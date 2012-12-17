package Redmine::KPI::Query::Factory;
use Badger::Class
	base => 'Badger::Factory',
;

our $ITEM	= 'query';
our $ITEMS	= 'queries';
our $QUERY_PATH	= 'Redmine::KPI::Query';

1;
