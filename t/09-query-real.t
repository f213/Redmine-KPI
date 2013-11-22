use strict;
use warnings;
use utf8;
use Test::More;
use File::Slurp qw /read_file/;
use Time::HiRes qw /time/;
use Class::Date qw /date/;

our $TEST_TASK_ID = 3324;
our $TEST_PRJ_ID = 1;
our $TEST_TRACKER_ID = 1;

our ($url, $auth_key);
eval 
{
	$url        = read_file ('./t/real_auth_data/url');
	$auth_key   = read_file ('./t/real_auth_data/auth_key');
};


if ( not $url or not $auth_key)
{
	plan skip_all => 'This tests need real auth data';
}
else
{
	unless($ENV{REAL_TESTS})
	{
		plan skip_all => "For running this test suite use 'make REAL_TESTS=1 test'";
	}
	plan tests => 21;
}
chomp $url;
chomp $auth_key;

use Redmine::KPI::Query::Trackers;

my $q = Redmine::KPI::Query::Trackers->new(
	url		=> $url,
	authKey 	=> $auth_key,
	noVerifyHost	=> 1,
);
ok($q->count > 0, 'Fetching remote trackers data');

use Redmine::KPI::Query::Issues;

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	noVerifyHost	=> 1,
	issue		=> [1,2,3,4],
);
$q->query;

is($q->count, 4, 'Result count in query did not change after actual query');
isa_ok($q->list->{1}->param('author'), 'Redmine::KPI::Element::User', 'And data from those elements is fetched');


$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	project		=> 8,
	noVerifyHost	=> 1,
);
my $firstProjectIssuesCount = $q->count;

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	project		=> 25,
	noVerifyHost	=> 1,
);
diag("Got $firstProjectIssuesCount from first project, ".$q->count." from second project");
cmp_ok($q->count, 'ne' , $firstProjectIssuesCount, 'Test filtering issues by project. Fetching issue list for two different projects, they must by not equal');

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	project		=> 8,
	tracker		=> 1,
	noVerifyHost	=> 1,
);
diag("Got $firstProjectIssuesCount total issues, ".$q->count." issues with tracker_id == 1");
cmp_ok($q->count, '<', $firstProjectIssuesCount, 'Test filtering issues by tracker. There must by less Issues with certain tracker, then total issues');


$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	project		=> 1,
	noVerifyHost	=> 1,
	limit		=> 5000,
);

# the next test is first to fail when redmine core is not modificated as described at http://search.cpan.org/~fborshev/Redmine-Stat-0.01/lib/Redmine/Stat.pm#DESCRIPTION and your $TEST_TASK_ID is too far from the end of the task list

# TODO - make a test to check if redmine core has modifications
my $i = $q->list->{$TEST_TASK_ID};
isa_ok($i, 'Redmine::KPI::Element::Issue', 'Got correct issue class in real env');
is($i->param('priority')->param('name'), 'Средний', 'Fetching remote parameter (priority)');

is($i->param('author')->param('login'), 'NikitaMelnikov', 'Fetching remote user login');
#after this everithing must be fetched, so we can check the full parameters tree

my $testHash = {
	id		=> '12',
	name		=> 'Никита Мельников',
	firstname	=> 'Никита',
	lastname	=> 'Мельников',
	mail		=> 'melnikov@shogo.ru',
	login		=> 'NikitaMelnikov',
};
is_deeply($i->param('author')->toHash, $testHash, 'Check full remote user info');

use Redmine::KPI::Query::Projects;

my $p = Redmine::KPI::Query::Projects->new(
	url	=> $url,
	authKey	=> $auth_key,
	noVerifyHost	=> 1,
);

isa_ok($p->list->{$TEST_PRJ_ID}, 'Redmine::KPI::Element::Project', 'Fetching projects');

$p = $p->list->{$TEST_PRJ_ID};


cmp_ok($p->timeEntries->totalTime, '>', 0, 'Fetching total time count for project');

my $totalTimeWithoutRounding = $p->timeEntries->totalTime;

$p = Redmine::KPI::Query::Projects->new(
	url     	=> $url,
	authKey 	=> $auth_key,
	roundHours 	=> 1,
	noVerifyHost	=> 1,
);
$p = $p->list->{$TEST_PRJ_ID};
my $totalTimeWithRounding = $p->timeEntries->totalTime;
cmp_ok($totalTimeWithRounding, '>', $totalTimeWithoutRounding, 'Check if config variable passing works, through projects to timeEntries');

$p = Redmine::KPI::Query::Projects->new(
	url     	=> $url,
	authKey 	=> $auth_key,
	roundHours 	=> 1,
	period		=> [ "2012-12-04", "2012-12-05" ],
	noVerifyHost	=> 1,
);

$p = $p->list->{$TEST_PRJ_ID};
my $totalTimeForTwoDaysWithRounding = $p->timeEntries->totalTime;
cmp_ok($totalTimeForTwoDaysWithRounding, '<', $totalTimeWithRounding, 'Check if config variable passing for periods is working');

$p = Redmine::KPI::Query::Projects->new(
	url     	=> $url,
	authKey 	=> $auth_key,
	roundHours 	=> 1,
	noVerifyHost	=> 1,
);

$p = $p->list->{$TEST_PRJ_ID};
is($p->timeEntries(period => ['2012-12-04', '2012-12-05'])->totalTime, $totalTimeForTwoDaysWithRounding, 'Check fetching time entries for period');

use Redmine::KPI::Element::User;

my $u = Redmine::KPI::Element::User->new(
	id	=> 14,
	url	=> $url,
	authKey	=> $auth_key,
	noVerifyHost	=> 1,
);

is($u->issues(period => ['2012-12-12', '2012-12-18'])->count, 24, 'Fetching user-created issues by period');
diag($u->issues->{url});

$i = Redmine::KPI::Element::Issue->new(
	id	=> 3650,
	url	=> $url,
	authKey	=> $auth_key,
	noVerifyHost	=> 1,
);

is($i->timeEntries(period => ['2012-12-12', '2012-12-17'])->totalTime, 18.3, 'Fetching timeEntries by issue for period');

use Redmine::KPI::CostProvider;

$q = Redmine::KPI::Query::Issues->new(
	url             => $url,
	authKey         => $auth_key,
	noVerifyHost	=> 1,
	project         => $TEST_PRJ_ID,
	costProvider	=> Redmine::KPI::CostProvider->new(
		'разработка' => 123,
		trackers	=> {
			'bUg'	=> 1.5,
		},
	),
	limit		=> 5000,
);

is($q->list->{$TEST_TASK_ID}->cost, 123*1.5, 'Check if task can count its own cost, plus check costProvider by trackers');
is($q->list->{$TEST_TASK_ID}->param('assignedTo')->customFields->getValue('Исполнитель задач'), 1, 'Check if customfields can be got from element itslef, not from query');

use Redmine::KPI::Query::Trackers;

my $t = Redmine::KPI::Query::Trackers->new(
	url             => $url,
	authKey         => $auth_key,
	noVerifyHost    => 1,
);

my $tracker = $t->{list}->{$TEST_TRACKER_ID};

isa_ok($tracker, 'Redmine::KPI::Element::Tracker', 'Fetching tracker');

my $tl = $tracker->issues;

isa_ok($tl, 'Redmine::KPI::Query::Issues');


my $task = pop @{$tl};

is($task->param('tracker')->param('id'), $TEST_TRACKER_ID, 'Fetching task by tracker');


