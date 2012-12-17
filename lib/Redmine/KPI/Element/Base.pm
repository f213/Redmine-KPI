package Redmine::KPI::Element::Base;
use Badger::Class
	base 		=> 'Badger::Base',
	accessors 	=> 'raw',
	methods		=> {
		_paramsFromConfig	=> sub { qw /id name/ },
		_paramsToFetch		=> sub { [] },
		_getUrl			=> sub {''},
		_init			=> sub {1},

		toHash			=> sub {shift->{param}},
	},

;
use Rose::URI;
use Redmine::KPI::Fetch;
use Redmine::KPI::Config;
use Redmine::KPI::Query::Factory;
use Redmine::KPI::Element::Factory;

sub init
{
	(my $self, my $config) = @_;

	$self->{config} = $config;
	
	$self->_setParamFromConfig($_) foreach($self->_paramsFromConfig());
	
	$self->{elemFactory}	= new Redmine::KPI::Element::Factory;
	$self->{queryFactory}	= new Redmine::KPI::Query::Factory; 

	$self->{isFetched} = 0;

	my $url = exists $self->{config}{url} ? $self->{config}{url} : '';
	$self->{url} = Rose::URI->new($url.'/'.$self->_getUrl());

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

	my @paramsToFetch = $self->_paramsToFetch;

	$self->query if $_[0] ~~ @paramsToFetch and not $self->{isFetched};

	return $self->{param}{$_[0]} if exists $_[0] and exists $self->{param}{$_[0]};
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
		$self->{raw} = $f->fetch($self->{url}, $self->{config}{authKey}) or $self->decline("Couldn't fetch remote data: ".$f->error());
		return 1;
	}
}

sub query
{
	my $self = shift;
	return if $self->{isFetched};

	$self->{isFetched} = $self->fetch() or $self->error("Couldn't get data");
	$self->{xml} = XML::LibXML->load_xml( string => $self->raw) or $self->error("Couldn't parse xml");
	$self->_parse() or $self->error("Couldn't parse data");

}
sub _elementFactory
{
	my $self = shift;
	my $paramName = shift;

	$self->param($paramName, $self->{elemFactory}->element($paramName, 
		passConfigParams($self->{config}),
		@_,
	));
}
sub _queryFactory
{
	my $self = shift;
	my $name = shift;

	return $self->{queries}{$name} if exists $self->{queries}{$name};
	
	$self->{queries}{$name} = $self->{queryFactory}->query($name, 
		passConfigParams($self->{config}),
		@_,
	);
}
1;
