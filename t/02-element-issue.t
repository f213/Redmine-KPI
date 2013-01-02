use strict;
use warnings;
use utf8;
use Test::More tests => 9;
use Redmine::KPI::Element::Issue;

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

is($i->param('nonexistant'), undef, 'checking undefined parameters');
