#!/usr/bin/perl
use strict;
use warnings;
use Redmine::KPI::Element::Project;
use Test::More tests => 2;


my $p = Redmine::KPI::Element::Project->new(
	id	=> '102',
	name	=> 'testPrj',
	dryRun	=> 1,
);

is(ref($p->timeEntries), 'Redmine::KPI::Query::TimeEntries', 'Test creating child time entries query');
is(ref($p->issues), 'Redmine::KPI::Query::Issues', 'Test creating child issues query');
