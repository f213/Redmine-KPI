package Redmine::KPI::Element::TimeEntry;
use Badger::Class
	base	=> 'Redmine::KPI::Element::Base',
;

sub cost
{
	my $self = shift;
	return $self->{config}{costProvider}->cost($self);
}

1;
