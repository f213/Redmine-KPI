package Redmine::KPI::Element::User;
use Badger::Class
	base 	=> 'Redmine::KPI::Element::Base',
	methods	=> {
		_paramsToFetch		=> sub { qw /login name firstname lastname mail/ },
		_paramsFromConfig	=> sub { qw /id name login firstname lastname mail admin/ }, # TODO - may be fetch 'admin' param somehow
		timeEntries		=> sub { shift->__queryFactory('timeEntries', @_) },
		issues			=> sub { my $self = shift; $self->_queryFactory('issues', author => $self->param('id'), @_) },
	},
;

sub _getUrl
{
	my $self = shift;

	my $url = 'users/' . $self->param('id') . '.xml';

	return $url;
}
sub _parse
{
	my $self = shift;
	
	($self->{rootNode}) = $self->{xml}->findnodes('user');
	
	$self->__addStdTextParam($_) foreach qw /login firstname lastname mail/;

	$self->param('name',	$self->param('firstname') . ' ' . $self->param('lastname'));
	1;
}

sub __addStdTextParam
{
	(my $self, my $param) = @_;
	
	$self->param($param,	$self->{rootNode}->findvalue($param));
}

sub __queryFactory
{
	my $self = shift;
	return $self->_queryFactory(shift,
		user         => $self->param('id'),
		@_,
	);
}

1;
