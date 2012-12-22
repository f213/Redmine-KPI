use strict;
use warnings;
use utf8;

use Test::More tests => 5;

use Redmine::KPI::Query::Issues;

my $q = Redmine::KPI::Query::Issues->new(
	xml 	=> 't/fixtures/issues.xml',
);

my @b = (346, 352, 366, 367, 391, 393, 408, 410, 411, 413, 416, 418, 424, 427, 428, 429, 430, 432, 433, 436, 438, 439, 441, 443, 444);

my @a;
foreach(@{ $q })
{
	push @a, $_->param('id');
}
is_deeply(\@a, \@b, 'Query to array');

ok($q == 25, 'Compare to integer');

my $q1 = Redmine::KPI::Query::Issues->new(
	xml	=> 't/fixtures/issues.xml',
	project	=> 68,
);
cmp_ok($q1, '<', $q, 'Compare to each other');


ok($q, 'query to bool(true)');

$q = Redmine::KPI::Query::Issues->new(
	xml	=> 't/fixtures/issues.xml',
	project	=> 123123123, #nonexistant
);

ok(!$q, 'query to bool(false)');


