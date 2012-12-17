package Redmine::KPI::Element::User;
use Badger::Class
	base 	=> 'Redmine::KPI::Element::Base',
	methods	=> {
		_paramsToFetch	=> sub { qw /login firstname lastname mail/ },
		timeEntries	=> sub { shift->__queryFactory('timeEntries', @_) },
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
	
	$self->__addStdParam($_) foreach qw /login firstname lastname mail/;
	1;
}

sub __addStdParam
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
