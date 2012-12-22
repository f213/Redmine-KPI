use strict;
use warnings;
use utf8;
use Test::More tests => 4;


use Redmine::KPI::Query::Issues;

my $q =  Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
);
is($q->count, 25, 'Fetching issues');
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




$q = Redmine::KPI::Query::Issues->new(
	issue	=> [1,2,3,4],
);

is($q->count, 4, 'Check building issue queries for certain ids');
