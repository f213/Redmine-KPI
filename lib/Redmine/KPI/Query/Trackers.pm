package Redmine::KPI::Query::Trackers;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl	=> sub {'trackers.xml'},
	},
;


sub _init
{
	my $self = shift;
	
	$self->{nodesNames} = 'trackers/tracker';
	$self->{elemName} = 'tracker';
}
1;
