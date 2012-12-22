package Redmine::KPI::Query::Base;
use utf8;
use Redmine::KPI::Element::Factory;
use Badger::Class
	base		=> 'Badger::Base',
	mutators	=> 'raw xml list',
	methods		=> {
		_getUrl		=> sub {''},	#path for the url
		_nodesName	=> sub {''},	#xml node names
		_elemName	=> sub {''},	#name of result Element from Redmine::KPI::Element
		_init		=> sub {1},	#custom subclass initialisation: custom filters, query params etc.
		_limit		=> sub {100},	#custom subclass query limit, might be more than 100, e.g. for TimeEntries. NOTE - needs modifications in redmine core
		_updateList	=> sub {1},	#subclass method to add custom parameters from xml
		_stdFilters	=> sub {()},	#subclass method to add custom filters
		_stdParams	=> sub {()},	#subclass method to add custom standard parameters
	},
	overload	=> {
		'@{}'	=> \&_asArray,
		'bool'	=> \&_asBool,
	},
;

use Redmine::KPI::Fetch;
use Redmine::KPI::Config;
use XML::LibXML;
use LWP::UserAgent;
require Crypt::SSLeay;
require IO::Socket::SSL;
use Rose::URI;


sub init
{
	(my $self, my $config) = @_;

	$self->{config} = $config; #i donna use Badger::Class::Config because if i would do so, i should write all of config variables in the top
	
	my $c = checkConfig($self->_elemName, $self->{config});
	$self->error($c) if $c;

	my $url = exists $self->{config}{url} ? $self->{config}{url} : '';
	$self->{url} = Rose::URI->new($url.'/'.$self->_getUrl());

	my $limit = exists $self->{config}{limit} ? $self->{config}{limit} : $self->_limit;
	$self->{url}->query_param(limit	=> $limit);

	$self->{elemFactory} = new Redmine::KPI::Element::Factory;
	
	foreach($self->_stdFilters)
	{
		$self->_addStdFilter($_, $self->{config}{$_}) if exists $self->{config}{$_};
	}

	$self->_init() or $self->error("Couldn't do class initialisation");
	
	if((not exists $self->{config}{dryRun} or not $self->{config}{dryRun}) and (not exists $self->{dryRun} or not $self->{dryRun}))
	{
		$self->query()
	}

	return $self;
}

sub query
{
	my $self = shift;
	$self->_fetch() or $self->error("Couldn't get data");

	$self->fatal('There is no raw xml data!') if not $self->raw;
	my $xml = XML::LibXML->load_xml( string => $self->raw) or $self->error("Couldn't parse xml");
	
	$self->xml($xml);

	$self->_makeList();
	$self->_updateCount();
	$self->_updateList();
	$self->_filterList();
}

sub count
{
	my $self = shift;
	if (not exists $self->{count} or not $self->{count})
	{
		return 0;
	}
	return $self->{count};
}
sub _fetch
{
	my $self = shift;
	
	my $f = Redmine::KPI::Fetch->instance();

	if (exists $self->{config}{xml} and length $self->{config}{xml})
	{ #fetching from local xml file
		my $raw = $f->fetch($self->{config}{xml}) or $self->error('Could not read file!');
		$self->raw($raw);
		return 1;
	}
	else 
	{ #fetching from remote host
		my $raw = $f->fetch($self->{url}, $self->{config}{authKey}) or $self->fatal("Couldn't fetch remote data: " . $f->error());
		$self->raw($raw);
		return 1;
	}
	return 0;
}


sub _addFilter
{
	my $self = shift;
	my %p = @_;
	return 0 if not exists $p{value};
	if (exists $p{get})
	{
		$self->{url}->query_param($p{get} => $p{value});
	}
	if(exists $p{local})
	{
		$self->{filterRules}{$p{local}} = $p{value};
	}
	1;
}
		

sub _filterList
{
	my $self = shift;

	my %r;
	foreach my $id (keys %{ $self->{list} })
	{
		my $passes = 1;
		foreach (keys %{ $self->{filterRules} }) #value of filterRules must be a scalar or a coderef. scalar values may be declared like 'project/id', this recursively evaluates to CLASS->param('project')->param('id')
		{
			my $paramName = $_;
			my @chain = split /\//; #recursively going inside parameters

			my $currentVal = $self->{list}{$id}->param(shift @chain);
			$currentVal = $currentVal->param($_)
				foreach(@chain);

			next if not $currentVal;
			
			if(ref($self->{filterRules}{$_}) eq 'CODE')
			{
				$passes = 0 if not &{ $self->{filterRules}{$_} }($currentVal);
			}
			else
			{
				$passes = 0 if $currentVal ne $self->{filterRules}{$_};
			}
		}
		$r{$id} = $self->{list}{$id} if $passes;
	}
	$self->{list} = \%r;
	$self->_updateCount;
			
	1;
}

sub _updateCount
{
	my $self = shift;

	$self->{count} = keys %{ $self->{list} };

}
sub _makeList
{
	my $self = shift;
	if(length $self->_nodesName)
	{
		foreach($self->xml->findnodes($self->_nodesName))
		{
			my $node = $_;
			my $id = $node->findvalue('id');

			$self->{list}{$id} = $self->_elementFactory($self->_elemName,
				id	=> $id,
				name	=> $_->findvalue('name'),
			);

			$self->_addStdParam($node, $_) foreach ($self->_stdParams);
		}
	}
}
sub _elementFactory
{
	my $self = shift;
	my $paramName = shift;
	return $self->{elemFactory}->element($paramName, 
		passConfigParams($self->{config}),
		@_,
	);
}
sub _addStdFilter
{
	my $self = shift;
	my $var = shift;
	our $val = shift;

	if($val =~ /^\d+$/) #by id
	{
		$self->_addFilter(
			local	=> "$var/id",
			value	=> $val,
			get	=> "$var\_id",
			@_,
		);
	}
	else
	{
		$self->_addFilter(
			local	=> "$var/name",
			value	=> sub { $_[0] =~ /^$val$/i ? 1 : 0 },
			@_,
		);
	}
}

sub _addStdParam
{
	my $self = shift;
	my $node = shift;
	my $name = shift;

	my $xmlParamName = $name;

	my $id = $node->findvalue('id');

	$name =~ s/_(.{0,1})/uc($1)/eg; #redmine snakecase to our camelcase
	$self->{list}{$id}->param($name,   $self->{elemFactory}->element($name,
			id	=> $node->findvalue("$name/\@id"),
			name	=> $node->findvalue("$name/\@name"),
		)
	);
}

	
sub _asArray
{
	my $self = shift;
	my @z = sort keys %{ $self->list };

	return \@z;
}
sub _asBool
{
	return shift->count ? 1 : 0;
}
1;
