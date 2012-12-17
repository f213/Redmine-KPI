use strict;
use warnings;
use utf8;
use Test::More tests => 11;


use Redmine::KPI::Query::TimeEntries;
use Redmine::KPI::Element::Issue;

my $q =  Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
);
is($q->count, 25, 'Fetching time entries');
undef $q;

$q =  Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	projectId	=> 1,
);
is($q->count, 6, 'Fetching time entries by project');

is($q->list->{4594}->param('hours'), '0.17', 'Fetch time entry hours');

is($q->totalTime, 3.37, 'Count total hours');

##hours rounding

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	projectId       => 1,
	roundHours	=> 1,
);

is($q->totalTime, 8, 'Count total hours with rounding');

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	projectId       => 1,
	minHours	=> 2,
);
is($q->totalTime, 12.5, 'Count total hours with minHours');

use Class::Date qw /date/;

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	period	=> ["2012-12-04", "2012-12-04"],
);
is($q->totalTime, 27.99, 'Count total hours with limit to one date');

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	period	=> date("2012-12-04"),
);
is($q->totalTime, 27.99, 'Count total hours with limit to one date (scalar)');

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	period	=> "2012-12-04",
);
is($q->totalTime, 27.99, 'Count total hours with limit to one date (scalar)');

#8.19
$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	period => '2012-12-04',
	activity => 'РазрАбоТка',
);
is($q->totalTime, 8.19, 'Count total hours with one date and activity name');

$q = Redmine::KPI::Query::TimeEntries->new(
	xml => 't/fixtures/time_entries.xml',
	period => '2012-12-04',
	activity => 9,
);
is($q->totalTime, 8.19, 'Count total hours with one date and activity id');

