package Redmine::KPI::Element::Base;
use utf8;
use Badger::Class
	base 		=> 'Badger::Base',
	accessors 	=> 'raw',
	methods		=> {
		_paramsFromConfig	=> sub { qw /id name/ },
		_paramsToFetch		=> sub { [] },
		_init			=> sub {1},
		toHash			=> sub {shift->{param}},
	},
;
use XML::LibXML;
use Rose::URI;
use Digest::SHA qw /sha1_hex/;
use Redmine::KPI::Fetch;
use Redmine::KPI::Config;
use Redmine::KPI::Query::Factory;
use Redmine::KPI::Element::Factory;
use Redmine::KPI::Element::CustomFields;

sub init

{
	(my $self, my $config) = @_;

	$self->{config} = $config;
	
	$self->_setParamFromConfig($_) foreach($self->_paramsFromConfig());
	
	$self->{isFetched} = 0;
	
	if($self->can('_getUrl')) # initialize Rose::URI only if we need it (subclass has defined _getUrl)
	{
		my $url = exists $self->{config}{url} ? $self->{config}{url} : '';
		$self->{url} = Rose::URI->new($url.'/'.$self->_getUrl());
	}

	$self->_init() or $self->fatal("Couldn't do class initialisation");

	return $self;
}

sub _setParamFromConfig
{
	(my $self, my $paramName) = @_;

	$self->{param}{$paramName} = $self->{config}{$paramName} if exists $self->{config}{$paramName};
}
sub param
{
	my $self = shift;

	@_ == 2 ? ( $self->{param}{$_[0]} = $_[1] ) : $self->getParam ($_[0]);
}
sub getParam
{
	my $self = shift;
	my $paramName = shift;

	my @paramsToFetch = $self->_paramsToFetch;
	
	$self->query if $paramName ~~ @paramsToFetch and not $self->{isFetched} and not exists $self->{param}{$paramName}; # fetching data if a param can be fetched, and is not set by some other way

	return undef if not exists $self->{param}{$paramName};
	return $self->{param}{$paramName};
}
sub fetch
{
	my $self = shift;

	my $f = Redmine::KPI::Fetch->instance();
	if (exists $self->{config}{xml} and length $self->{config}{xml})
        {
                $self->{raw} = $f->fetch($self->{config}{xml});
                return 1;
        }
	else
	{
		$self->{raw} = $f->fetch($self->{url}, $self->{config}{authKey}, $self->{config}) or $self->decline("Couldn't fetch remote data: ".$f->error());
		return 1;
	}
}

sub query
{
	my $self = shift;
	return if $self->{isFetched};

	$self->{isFetched} = $self->fetch() or $self->error("Couldn't get data");
	$self->{xml} = XML::LibXML->load_xml( string => $self->raw) or $self->error("Couldn't parse xml");
	$self->_parse() or $self->error("Couldn't parse data"); # subclass must define $self->{rootNode} here
	$self->_parseCustomFields();

}

sub customFields
{ # this method is commonly used for fetching custom field data. For creating new customfields one must use customFieldAdd
	my $self = shift;
	
	if(not exists $self->{customFields})
	{
		$self->{customFields} = new Redmine::KPI::Element::CustomFields;
		$self->query if not $self->{isFetched};
	}
	$self->{customFields};
}

sub customFieldsAdd
{
	my $self = shift;
	
	$self->{customFields} = new Redmine::KPI::Element::CustomFields if not exists $self->{customFields};
	$self->{customFields}->add(@_);
}

sub _elementFactory
{
	my $self = shift;
	my $paramName = shift;
	$self->{elementFactory}	= new Redmine::KPI::Element::Factory if not exists $self->{elementFactory};

	my $cacheKey = sha1_hex($paramName, @_);

	return $self->{elements}{$cacheKey} if exists $self->{elements}{$cacheKey};

	my $el = $self->{elementFactory}->element($paramName, 
		passConfigParams($self->{config}),
		@_,
	);
	$self->{elements}{$cacheKey} = $el if not exists $self->{config}{__noElementCache__} and not exists $self->{config}{__noCache__};
}
sub _queryFactory
{
	my $self = shift;
	my $name = shift;
	
	$self->{queryFactory}	= new Redmine::KPI::Query::Factory if not exists $self->{queryFactory};

	my $cacheKey = sha1_hex($name, @_);

	return $self->{queries}{$cacheKey} if exists $self->{queries}{$cacheKey};
	
	my $q = $self->{queryFactory}->query($name, 
		passConfigParams($self->{config}),
		@_,
	);
	$self->{queries}{$cacheKey} = $q if not exists $self->{config}{__noQueryCache__} and not exists $self->{config}{__noCache__};
	$q;
}
sub _addStdParam
{
	my $self = shift;
	my $paramName = shift;
	my $xmlParamName = $paramName;

	$paramName =~ s/_(.{0,1})/uc($1)/eg; #redmine snakecase to our camelcase

	$self->param($paramName,	$self->_elementFactory($paramName,
		id	=> $self->{rootNode}->findvalue("$xmlParamName/\@id"),
		name	=> $self->{rootNode}->findvalue("$xmlParamName/\@name"),
	));
}

sub _parseCustomFields
{
	my $self = shift;

	foreach($self->{rootNode}->findnodes('custom_fields/custom_field'))
	{
		$self->customFieldsAdd(
			id	=> $_->getAttribute('id'),
			name	=> $_->getAttribute('name'),
			value	=> $_->findvalue('value'),
		);
	}
}
1;
