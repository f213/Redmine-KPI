use strict;
use warnings;
use utf8;
use Test::More tests => 11;


use Redmine::KPI::Query::Issues;
use Redmine::KPI::Element::Issue;

my $q =  Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
);
is($q->count, 25, 'Fetching issues');
undef $q;

$q =  Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
	projectId => 50,
);

is($q->count, 6, 'Fetching issues by project');

$q = Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
	trackerId => 3,
);

is($q->count, 5, 'Fetching issues by tracker');


my $i = Redmine::KPI::Element::Issue->new(
	xml => 't/fixtures/issue.xml',
);

my $priorityHash = {
	id	=> 4,
	name	=> 'Средний',
};
is_deeply($i->param('priority')->toHash, $priorityHash, 'fetching issue priority');

my $statusHash = {
	id	=> 3,
	name	=> 'Выполнена',
};
is_deeply($i->param('status')->toHash, $statusHash, 'fetching issue status');

my $authorHash = {
	id	=> 12,
	name	=> 'AuthorName',
};
is_deeply($i->param('author')->toHash, $authorHash, 'fetching issue author');

my $assignedToHash = {
	id	=> 13,
	name	=> 'AssigneeName',
};
is_deeply($i->param('assignedTo')->toHash, $assignedToHash, 'Fetching issue assignee');

is($i->param('description'), 'Поменять условие принятия ean13', 'Fetching issue description');

is(ref($i->param('changesets')->{'3a6f0c84c082a8548a4599de6042205120dc5bed'}), 'Redmine::KPI::Element::ChangeSet', 'Fetching changesets (simple test)');
is(ref($i->param('changesets')->{'3a6f0c84c082a8548a4599de6042205120dc5bed'}->param('user')), 'Redmine::KPI::Element::User', 'User inside changeset');
is(keys %{ $i->param('changesets') }, 2, 'All changesets are fetched');


