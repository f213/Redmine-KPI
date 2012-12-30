package Redmine::KPI::Query::Base;
use utf8;
use Redmine::KPI::Element::Factory;
use Redmine::KPI::Query::Factory;
use Badger::Class
	base		=> 'Badger::Base',
	mutators	=> 'raw xml list',
	methods		=> {
		_getUrl		=> sub {''},		# path to the url of query
		_nodesName	=> sub {''},		# xml node names. Every subclass must define it
		_elemName	=> sub {''},		# name of result Element from Redmine::KPI::Element. Bunch of that eleents is all what we produce:)
		_init		=> sub {1},		# custom subclass initialisation: custom filters, query params etc.
		_limit		=> sub {100},		# custom subclass query limit, might be more than 100, e.g. for TimeEntries. NOTE - needs modifications in redmine core
		_updateList	=> sub {1},		# subclass method to add custom parameters from xml. Every subclass that need non-std parameters must fetch them in this method
		_stdFilters	=> sub {()},		# subclass method to add custom filters. stdFilter is a filter for an xml tag like '<something name = "name" id = 1>".
		_stdParams	=> sub {()},		# subclass method to add custom standard parameters. stdParam is some Element:: instance with two parameters - id and name, which is added as a ->param to elements which we produce
		_txtParams	=> sub {qw/name/},	# subclass method to text searchable params. The first of this param used as default searchable param in filter()
	},
	overload	=> {
		'@{}'	=> \&_asArray,
		'bool'	=> \&_asBool,
		'0+'	=> \&_asInt,
		'<=>'	=> \&_cmp, #only binary comparison, i dont need full yet.
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

	$self->{elemFactory} 	= new Redmine::KPI::Element::Factory;
	$self->{queryFactory}	= new Redmine::KPI::Query::Factory;
	
	foreach($self->_stdFilters)
	{
		$self->_addStdFilter($_, $self->{config}{$_}) if exists $self->{config}{$_};
	}

	$self->_init() or $self->error("Couldn't do class initialisation");
	
	if((not exists $self->{config}{dryRun} or not $self->{config}{dryRun}) and (not exists $self->{dryRun} or not $self->{dryRun})) #{config}{dryRun} is set by user (e.g. for testing) and {dryRun} we set ourselves
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

	$self->_makeList(); #first-time creating the list with stdParams and default params like id or name
	$self->_updateList(); #updating the list with custom params
	$self->_filterList();
}

sub count
{
	my $self = shift;
	exists $self->{count} and $self->{count} ? $self->{count} : 0;
}
sub find
{
	my $self = shift;
	my $what = shift;

	#TODO search by custom fields, giving this method a hash instead of scalar, or may be write other method
	foreach(@{ $self })
	{
		if($what =~ /^\d+$/)
		{
			return $_ if $_->param('id') eq $what;
		}
		else
		{
			foreach my $p ($self->_txtParams)
			{
				return $_ if $_->param($p) eq $what; #TODO - coderef support here
			}
		}
	}
}

sub filter
{
	my $self = shift;
	my %f =  @_ ;

	foreach (keys %f)
	{
		if(/\//) #default __addFilter syntax like 'tracker/id'. Passing it directly
		{
			$self->_addFilter(
				local	=> $_,
				value	=> $f{$_},
			);
		}
		else 
		{ #here we can get something like tracker=>'3' or tracker=>'Bug'. 
			if($f{$_} =~ /^\d+$/) #for the first one
			{
				$self->_addFilter(
					local	=> "$_/id",
					value	=> $f{$_},
				);
			}
			else
			{ #and for the second
				my @p = $self->_txtParams;
				our $val = $f{$_};
				$self->_addFilter(
					local	=> "$_/" . $p[0],
					value	=> sub { $_[0] =~ /^$val$/i ? 1 : 0 }, #if param val matches $val, then it will pass
				);
			}
		}
	}
	$self->_filterList();
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
		# search by parameters
		foreach (keys %{ $self->{filterRules} }) #value of filterRules must be a scalar or a coderef. scalar values may be declared like 'project/id', this recursively evaluates to CLASS->param('project')->param('id')
		{
			my $paramName = $_;
			my @chain = split /\//; #recursively going inside parameters

			my $currentVal = $self->{list}{$id}->param(shift @chain); #first param. and may be the last. If the last, then overloading must begin to work, but i dont know what will happen, so please dont do that!
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
		# search by custom field values
		foreach (keys %{ $self->{config}{customFields} })
		{
			my $element = $self->{list}{$id};
			$passes = 0 if defined $element->customFields->getValue($_) and $element->customFields->getValue($_) ne $self->{config}{customFields}{$_};
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
		foreach($self->xml->findnodes($self->_nodesName)) #every subclass defines _nodeName
		{
			my $node = $_;
			my $id = $node->findvalue('id');

			$self->{list}{$id} = $self->_elementFactory($self->_elemName, #elemName is the name of element, bunch of which every our subclass is producing. Names must be the same here, and in the factory
				id	=> $id,
				name	=> $_->findvalue('name'),
			);

			$self->_addStdParam($node, $_) foreach ($self->_stdParams); #every subclass defined _stdParams

			$self->_addCustomFields($id, $node);
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
sub _queryFactory
{
	my $self = shift;
	my $paramName = shift;
	return $self->{queryFactory}->query($paramName,
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
		my @p = $self->_txtParams; #using the first of _txtParams as default compare param
		$self->_addFilter(
			local	=> "$var/$p[0]",
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

	$name =~ s/_(.{1})/uc($1)/eg; #redmine snakecase to our camelcase
	$self->{list}{$id}->param($name,   $self->{elemFactory}->element($name,
			id	=> $node->findvalue("$name/\@id"),
			name	=> $node->findvalue("$name/\@name"),
		)
	);
}
sub _addCustomFields
{
	my $self = shift;
	my $id = shift;
	my $node = shift;

	foreach($node->findnodes('custom_fields/custom_field'))
	{
		$self->{list}{$id}->customFields->add(
			id	=> $_->getAttribute('id'),
			name	=> $_->getAttribute('name'),
			value	=> $_->findvalue('value'),
		);
	}
	
}
	
sub _asArray
{
	my $self = shift;
	my @z;
	push @z, $self->{list}{$_} foreach sort keys %{ $self->list };

	return \@z;
}
sub _asBool	{ shift->count ? 1 : 0 }
sub _asInt	{ shift->count }
sub _cmp	{ int(shift) <=> int(shift) } #this is sort of magic, we can compare instance to instance, or instance to integer. int($class) == int(25) is true when $class->_asInt == 25

1;
