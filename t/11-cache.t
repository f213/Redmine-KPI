#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp qw/read_file/;
use Time::HiRes qw/time/;
use Test::More;

use Redmine::KPI;

our $TEST_PRJ_ID = 1;

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
        plan tests => 3;
}
chomp $url;
chomp $auth_key;


my $k = Redmine::KPI->new(
        url     => $url,
        authKey => $auth_key,
        noVerifyHost    => 1,
);

my $prj = $k->project($TEST_PRJ_ID);

my $t;

bail_out('Could not find project with $TEST_PRJ_ID=' . $TEST_PRJ_ID) unless $prj->isa('Redmine::KPI::Element::Project');

diag('Fetching timeEntries for the first time');
$t = time();
$prj->timeEntries;
my $timeout1 = time() - $t;
diag('Done');

diag('Fetching timeEntries for the second time');
$t = time();
$prj->timeEntries;
my $timeout2 = time() - $t;
diag('Done');

cmp_ok($timeout2 * 3, '<', $timeout1, 'Second time fetching timeEntries must hit queryCache');


my $k1 = Redmine::KPI->new(
	url		=> $url,
	authKey		=> $auth_key,
	noVerifyHost	=> 1,
);
diag('Fetching timeEntries from the new instance of Redmine::KPI');
$t = time();
$k1->project($TEST_PRJ_ID)->timeEntries;
my $timeout3 = time() - $t;
diag('Done');

cmp_ok($timeout3 * 3, '<', $timeout1, 'Fetching from new instance of Redmine::KPI must also work (fetcher is a singleton)');


$k1 = Redmine::KPI->new(
	url			=> $url,
	authKey			=> $auth_key,
	noVerifyHost		=> 1,
	__noFetchCache__	=> 1,
);

diag('Fetching timeEntries from the new instance of Redmine::KPI (fetch cache turned off)');
$t = time();
$k1->project($TEST_PRJ_ID)->timeEntries;
my $timeout4 = time() - $t;
diag('Done');

cmp_ok($timeout4 * 2, '>', $timeout1, 'Fetching from new instance of Redmine::KPI with fetchCache turned off');


