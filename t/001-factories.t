#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8;

use_ok('Redmine::KPI::Element::Factory');

use Redmine::KPI::Element::Factory;
new_ok('Redmine::KPI::Element::Factory');

my $f = new Redmine::KPI::Element::Factory;

my $t = $f->element('Issue', id => 100500, name => '100500name');

is(ref($t), 'Redmine::KPI::Element::Issue', 'Factory test, getting issues object');
is($t->param('id'), 100500, 'Check passing parameters to elem constructor via fabric');
is($t->param('name'), '100500name', 'Check passing parameters to elem constructor via fabric (there was my bug with this)');

use_ok('Redmine::KPI::Query::Factory');

use Redmine::KPI::Query::Factory;
new_ok('Redmine::KPI::Query::Factory');

$f = new Redmine::KPI::Query::Factory;

my $q = $f->query('TimeEntries', id => 100500, name => '100500name', dryRun => 1);

is(ref($q), 'Redmine::KPI::Query::TimeEntries', 'Factory test, getting timeentries query');
