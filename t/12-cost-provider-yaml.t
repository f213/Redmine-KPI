#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use Redmine::KPI::Query::TimeEntries;
use Redmine::KPI::CostProvider::YAML;

my $t = Redmine::KPI::Query::TimeEntries->new(
	        xml     => 't/fixtures/time_entries.xml'
);

my $kp = Redmine::KPI::CostProvider::YAML::create('t/fixtures/costs.yml');

isa_ok($kp, 'Redmine::KPI::CostProvider');
is($kp->cost($t->list->{4574}), 7.3*200*1.5, 'Cost counting');
