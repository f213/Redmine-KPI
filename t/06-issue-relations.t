use strict;
use warnings;
use utf8;
use Test::More tests => 6;

use Redmine::KPI::Element::Issue;

my $i = Redmine::KPI::Element::Issue->new(
	id	=> 3324,
        xml => 't/fixtures/issue.xml',
);
is($i->param('relatedToMe')->list->{3185}->param('id'), 3185, 'Fetching relatedToMe issues');
is($i->param('relatedFromMe')->list->{3648}->param('id'), 3648, 'Fetching relatedFromMe issues');
is($i->param('children')->count, 2, 'Fetching issue children');
is($i->param('children')->list->{3386}->param('id'), 3386, 'Fetching issue children (one more check)');
is($i->param('relations')->count, 2, 'Fetching complete issue relations (without children)');

is($i->param('parent')->param('id'), 3384, 'Fetching parent issue');

