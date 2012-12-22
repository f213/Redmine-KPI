use strict;
use warnings;
use utf8;
use Test::More tests => 5;
use Carp;
use Data::Dumper;
use Redmine::KPI::Query::Issues;
use Redmine::KPI::Query::Projects;
use Redmine::KPI::Query::Trackers;

my $q = Redmine::KPI::Query::Issues->new(
	xml => 't/fixtures/issues.xml',
);

open (TESTXML, '<', 't/fixtures/issues.xml');
my $testXml;
$testXml.=$_ while(<TESTXML>);
close TESTXML;

is($q->raw, $testXml, 'Returning raw XML');

is(ref($q->xml), 'XML::LibXML::Document', 'Parsing XML');




$q = Redmine::KPI::Query::Projects->new(
	xml => 't/fixtures/projects_no_meta.xml',
);
is($q->count, 25, 'R::K::Q::Projects count without meta');


$q = Redmine::KPI::Query::Projects->new(
	xml => 't/fixtures/projects.xml',
);

my $testHash = {
	id	=> 66,
	name	=> 'paef6ez0iePhu2e',
	redmineId => 'ahph5Tho6iTh9la',
	description => 'Российское представительство канадской компании paef6ez0iePhu2e. Сайт полностью на нас.',
};
is_deeply($q->list->{66}->toHash, $testHash, 'Fetching project list');

$q = Redmine::KPI::Query::Trackers->new(
	xml => 't/fixtures/trackers.xml',
);
$testHash = {
	id	=> 8,
	name	=> 'Immediate',
};

is_deeply($q->list->{8}->toHash, $testHash, 'Fetching trackers list');


