use strict;
use warnings;

use Test::More tests => 4;

use Redmine::KPI::Query::Projects;

my $q = Redmine::KPI::Query::Projects->new(
	xml => 't/fixtures/projects.xml',
	dryRun	=> 1,
);

is($q->{url}, '/projects.xml?limit=100', 'Autosetting url in query children');

use Redmine::KPI::Query::TimeEntries;

my $t = Redmine::KPI::Query::TimeEntries->new(
	url	=> 'https://redmine.shogo.ru',
	authKey	=> 'secret',
	dryRun	=> 1,
);
is($t->{url}->as_string, 'https://redmine.shogo.ru/time_entries.xml?limit=1000', 'Rewriting query limit in subclasses');

use Redmine::KPI::Element::Issue;

my $i = Redmine::KPI::Element::Issue->new(
	url	=> 'https://redmine.shogo.ru',
	id	=> 100500,
);

is($i->{url}->as_string, 'https://redmine.shogo.ru/issues/100500.xml?include=children%2Crelations%2Cchangesets', 'Autosetting url in elements children');


use Redmine::KPI::Query::Issues;
$i = Redmine::KPI::Query::Issues->new(
	url	=> 'https://redmine.shogo.ru',
	dryRun	=> 1,
);
is($i->{url}->as_string, 'https://redmine.shogo.ru/issues.xml?limit=100&status_id=%2A', 'Autosetting issues query url');
