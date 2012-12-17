use strict;
use warnings;
use utf8;
use Test::More;
use File::Slurp qw /read_file/;
use Time::HiRes qw /time/;
use Class::Date qw /date/;

our $TEST_TASK_ID = 3324;
our $TEST_PRJ_ID = 1;

our ($url, $auth_key, $query_id);
eval 
{
	$url        = read_file ('./t/real_auth_data/url'); chomp $url;
	$auth_key   = read_file ('./t/real_auth_data/auth_key'); chomp $auth_key;
	$query_id   = read_file ('./t/real_auth_data/query_id'); chomp $query_id;
};


if ( not length $url or not length $auth_key or not length $query_id)
{
	plan skip_all => 'This tests need real auth data';
}
else
{
	#plan tests => 13;
	plan skip_all => 'Temporary disabled';
}


use Redmine::KPI::Query::Trackers;

my $q = Redmine::KPI::Query::Trackers->new(
	url	=> $url,
	authKey => $auth_key,
);
ok($q->count > 0, 'Fetching remote trackers data');

use Redmine::KPI::Query::Issues;

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	projectId	=> 8,
);
my $firstProjectIssuesCount = $q->count;

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	projectId	=> 25,
);
diag("Got $firstProjectIssuesCount from first project, ".$q->count." from second project");
cmp_ok($q->count, 'ne' , $firstProjectIssuesCount, 'Test filtering issues by project. Fetching issue list for two different projects, they must by not equal');

$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	projectId	=> 8,
	trackerId	=> 1,
);
diag("Got $firstProjectIssuesCount total issues, ".$q->count." issues with tracker_id == 1");
cmp_ok($q->count, '<', $firstProjectIssuesCount, 'Test filtering issues by tracker. There must by less Issues with certain tracker, then total issues');


$q = Redmine::KPI::Query::Issues->new(
	url		=> $url,
	authKey		=> $auth_key,
	projectId	=> 1,
);

my $i = $q->list->{$TEST_TASK_ID};
is(ref($i), 'Redmine::KPI::Element::Issue', 'Got correct issue class in real env');
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
);

is(ref($p->list->{$TEST_PRJ_ID}), 'Redmine::KPI::Element::Project', 'Fetching projects');

$p = $p->list->{$TEST_PRJ_ID};
my $t = time();
diag('Fetching time entries for the first time');
is(ref($p->timeEntries), 'Redmine::KPI::Query::TimeEntries', 'Fetching project time entries');
diag('done');
my $timeout1 = time() - $t;

$t = time();
diag('Fetching time entries for the second time');
my $t1 = $p->timeEntries;
diag('done');
diag('Fetching time entries for the third time');
my $t2 = $p->timeEntries;
diag('done');
my $timeout2 = time() - $t;

cmp_ok($t1, 'eq', $t2, 'Building child queries is singleton-like'); #TODO move this test to other file, make it work without auth data
cmp_ok($timeout2 * 3, '<' , $timeout1, 'While getting child query we do not process it two times'); 

cmp_ok($p->timeEntries->totalTime, '>', 0, 'Fetching total time count for project');

my $totalTimeWithoutRounding = $p->timeEntries->totalTime;

$p = Redmine::KPI::Query::Projects->new(
	url     	=> $url,
	authKey 	=> $auth_key,
	roundHours 	=> 1,
);
$p = $p->list->{$TEST_PRJ_ID};
my $totalTimeWithRounding = $p->timeEntries->totalTime;
cmp_ok($totalTimeWithRounding, '>', $totalTimeWithoutRounding, 'Check if config variable passing works, through projects to timeEntries');

#$p->timeEntriesLimit(date "2012-12-01", date "2012-30-01");
#my $totalTime1Month = $p->timeEntries->totalTime;
#cmpl_ok($totalTime1Month, '>', $totalTimeWithoutRounding, 'Check if timeEntries limit works');

