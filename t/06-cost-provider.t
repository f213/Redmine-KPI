#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use Redmine::KPI::CostProvider;
use Redmine::KPI::Query::TimeEntries;
use utf8;

my $t = Redmine::KPI::Query::TimeEntries->new(
	xml	=> 't/fixtures/time_entries.xml'
);

my $kp = Redmine::KPI::CostProvider->new(
	'12:Контент'	=> 100,
	'9:Разработка'	=> 200,
);
is($kp->cost($t->list->{4574}), 7.3*200, 'Check rate counting by timeEntry');
$kp = Redmine::KPI::CostProvider->new(
	'100500:рАзРаботка'	=> 200,
);
is($kp->cost($t->list->{4574}), 7.3*200, 'Check rate counting by timeEntry (param as name)');


$kp = Redmine::KPI::CostProvider->new(
	'100500:testNullCost'	=> 200,
);
is($kp->cost($t->list->{4574}), 0, 'Check rate counting with anknown activity');
