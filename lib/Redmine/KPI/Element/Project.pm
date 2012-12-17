package Redmine::KPI::Element::Project;
use Badger::Class
	base		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		issues		=> sub {shift->__queryFactory('issues')},
		timeEntries	=> sub {shift->__queryFactory('timeEntries')},
	},
;

sub __queryFactory
{ #this method is designed to add self id to the child query, because i want to write less code above, and dont know anything about parent:: in perl
	my $self = shift;
	return $self->_queryFactory(shift,
		project		=> $self->param('id'),
		@_,
	);
}

1;
