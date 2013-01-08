use strict;
use warnings;
use utf8;
use Test::More;
use File::Slurp qw /read_file/;
use Encode qw /encode/;
my $TEST_PROJECT = 1;
my $TEST_PERIOD	= ['2012-12-01', '2012-12-31' ];


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
	plan tests => 2;
}
chomp $url;
chomp $auth_key;

use Redmine::KPI;

my $k = Redmine::KPI->new(
	url		=> $url,
	authKey		=> $auth_key,
	noVerifyHost	=> 1,
);
my $costProvider = $k->costProvider(
        'Разработка'    => 700,
        'Дизайн'        => 500,
        'Тестирование'  => 500,
        'Саппорт'       => 700,
        'Контент'       => 400,
        'Верстка'       => 500,
);

my $prj = $k->project($TEST_PROJECT);
my $entries = $prj->timeEntries(
	period		=> $TEST_PERIOD,
	costProvider	=> $costProvider,
);

my %issues;

foreach my $entry ( @{ $entries } )
{
	my $issue	= $entry->param('issue');
	my $parentIssue	= $issue->param('parent');

	$issue = $parentIssue if $parentIssue;

	$issues{$issue->param('id')}{name}	= 'name';
	$issues{$issue->param('id')}{cost}	+= $entry->cost;
}

my $f = read_file('t/reference-report.csv');

my %issuesTest;
my $totalCost;
foreach (split /\n/, $f)
{
	chomp;
	(my $id, my $name, my $cost) = split /;/;
	$issuesTest{$id}{name} = $name;
	$issuesTest{$id}{cost} = $cost;
	$totalCost += $cost;
}

is_deeply(\%issues, \%issuesTest, 'Test creating simple project cost report');

my $prjCost = $prj->cost(
	period		=> $TEST_PERIOD,
	costProvider	=> $costProvider,
);

is($prjCost, $totalCost, 'Test detail report versus project cost count by project::cost');
