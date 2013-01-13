package Redmine::KPI::Element::Project;
use Badger::Class
	base		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		_paramsToFetch  => sub { qw /name identifier description homepage/ },
		issues		=> sub {shift->__queryFactory('issues', @_)},
		timeEntries	=> sub {shift->__queryFactory('timeEntries', @_)},
	},
;
sub _getUrl
{
	my $self = shift;
	my $url = 'projects/' . $self->param('id') . '.xml' if $self->param('id');
}
sub _parse
{
	# TODO - cover this with tests!
	my $self = shift;
	($self->{rootNode}) = $self->{xml}->findnodes('project');

	$self->param($_, $self->{rootNode}->findvalue($_)) foreach qw /name identifier description homepage/;
	1;
}

sub cost
{
	my $self = shift;

	$self->timeEntries(@_)->cost;
}


sub __queryFactory
{ #this method is designed to add self id to the child query, because i want to write less code above, and dont know anything about parent:: in perl
	my $self = shift;
	return $self->_queryFactory(shift,
		project		=> $self->param('id'),
		@_,
	);
}

1;
