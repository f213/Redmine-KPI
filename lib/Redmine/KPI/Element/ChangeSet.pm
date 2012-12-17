package Redmine::KPI::Element::ChangeSet;
use Badger::Class
	base	=> 'Redmine::KPI::Element::Base',
;

sub _paramsFromConfig { qw /id comments commitedOn user/; };

1;
