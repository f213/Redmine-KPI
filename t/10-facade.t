use strict;
use warnings;
use utf8;
use Test::More;
use File::Slurp qw /read_file/;
use Time::HiRes qw /time/;

our $TEST_USER_ID = 5;
our $TEST_USER_HASH = {
	id		=> 5,
	login		=> 'fedor',
	firstname	=> 'Федор',
	lastname	=> 'Борщев',
	name		=> 'Федор Борщев',
	mail		=> 'fedor@shogo.ru',
};

our ($url, $auth_key);
eval
{
	$url        = read_file ('./t/real_auth_data/url');
	$auth_key   = read_file ('./t/real_auth_data/auth_key');
};
if ( not $url or not $auth_key)
{
	plan skip_all => 'This tests need real auth data',
}
else
{
	unless($ENV{REAL_TESTS})
	{
		plan skip_all => "For running this test suite use 'make REAL_TESTS=1 test'";
	}
	plan tests => 7;
}
chomp $url;
chomp $auth_key;

use Redmine::KPI;

my $k = Redmine::KPI->new(
	url		=> $url,
	authKey		=> $auth_key,
	autoFetch	=> 1,
);

my $user = $k->user($TEST_USER_ID);

$user->param('login');
is_deeply($user->toHash, $TEST_USER_HASH, 'Finding one user by id');

my @users = @{$k->users()};
my $testHashGotFromQuery;

foreach(@users)
{
	if ($_->param('id') == $TEST_USER_ID)
	{
		$_->param('login'); #let it fetch everything;
		$testHashGotFromQuery = $_->toHash;
	}
}
is_deeply($testHashGotFromQuery, $TEST_USER_HASH, 'getting list of users');

$user = $k->user('Федор Борщев');
is_deeply($user->toHash, $TEST_USER_HASH, 'Finding one user by name');

TODO:
{	
	todo_skip 'not ready yet', 1;
	$user = $k->user(name=>'Федор Борщев');
	is_deeply($user->toHash, $TEST_USER_HASH, 'Finding one user by name hash');
}

ok(!$user->param('BadParamName'), 'nonexistant param name');

$user = $k->user('Nonexistant');
ok(!$user, 'nonexistant element');

diag('Fetching for the first time');
my $t = time();
$user = $k->issue(1);
my $timeout1 = time() - $t;

diag('Fetching for the second time must be from cache');
$t = time();
$user = $k->issue(1);
my $timeout2 = time() - $t;
diag('Done');

cmp_ok($timeout2 * 3, '<' , $timeout1, 'Cache');