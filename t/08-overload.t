use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Redmine::KPI::Query::Issues;

my $q = Redmine::KPI::Query::Issues->new(
	xml 	=> 't/fixtures/issues.xml',
);

my @a = @{ $q };
my @b = (346, 352, 366, 367, 391, 393, 408, 410, 411, 413, 416, 418, 424, 427, 428, 429, 430, 432, 433, 436, 438, 439, 441, 443, 444);

is_deeply(\@a, \@b, 'Query to array');

ok($q, 'query to bool(true)');

$q = Redmine::KPI::Query::Issues->new(
	xml	=> 't/fixtures/issues.xml',
	project	=> 123123123, #nonexistant
);

ok(!$q, 'query to bool(false)');

