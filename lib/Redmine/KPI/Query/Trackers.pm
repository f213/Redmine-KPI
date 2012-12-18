package Redmine::KPI::Query::Trackers;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl		=> sub {'trackers.xml'},
		_nodesName	=> sub {'trackers/tracker'},
		_elemName	=> sub {'tracker'},
	},
;
1;
