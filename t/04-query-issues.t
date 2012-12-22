use strict;
use warnings;
use utf8;
use Test::More tests => 9;


use Redmine::KPI::Query::Issues;

my $q =  Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
);
is($q->count, 25, 'Fetching issues');

my $i = $q->find(441);
is($i->param('id'), 441, 'Finding issue by id in query');

undef $q;

$q =  Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
	project => 50,
);

is($q->count, 6, 'Fetching issues by project');

$q = Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
	tracker => 3,
);

is($q->count, 5, 'Fetching issues by tracker');



FILTERS:
{
	$q = Redmine::KPI::Query::Issues->new(
		xml	=> 't/fixtures/issues.xml',
	);
	$q->filter(tracker=>3);
	is($q->count, 5, 'Filtering issues by tracker id');

	$q = Redmine::KPI::Query::Issues->new(
		xml	=> 't/fixtures/issues.xml',
	);
	$q->filter(tracker=>'support');
	is($q->count, 5, 'Filtering issues by tracker name');

	$q = Redmine::KPI::Query::Issues->new(
		xml	=> 't/fixtures/issues.xml',
	);
	$q->filter('tracker/id'=>3);
	is($q->count, 5, 'Filtering issues by param name/val');
}




$q = Redmine::KPI::Query::Issues->new(
	issue	=> [1,2,3,4],
);

is($q->count, 4, 'Check building issue queries for certain ids');

#bug? no issues count

$q = Redmine::KPI::Query::Issues->new(
	xml	=> 't/fixtures/issues.xml',
	project	=> 1005001,
);

is($q->count, 0 , 'Check for (bug?) count in empty queries list');


