package Redmine::KPI::Element::Project;
use Badger::Class
	base		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		issues		=> sub {shift->__queryFactory('issues', @_)},
		timeEntries	=> sub {shift->__queryFactory('timeEntries', @_)},
	},
;

sub cost
{ # TODO WRITE A TEST FOR THAT!
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
