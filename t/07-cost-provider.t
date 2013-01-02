#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use Redmine::KPI;
use Redmine::KPI::CostProvider;
use Redmine::KPI::Query::TimeEntries;
use utf8;

my $t = Redmine::KPI::Query::TimeEntries->new(
	xml	=> 't/fixtures/time_entries.xml'
);

my $k = new Redmine::KPI;
my $kp = $k->costProvider(
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


$t = Redmine::KPI::Query::TimeEntries->new(
	xml		=> 't/fixtures/time_entries.xml',
	costProvider	=> Redmine::KPI::CostProvider->new(
		'разработка'	=> 300,
		'верстка'	=> 200,
		'дизайн'	=> 100,
		'контент'	=> 50,
		'Тестирование'	=> 25,
		'Саппорт'	=> 15,
	),
);

is($t->list->{4574}->cost, 7.3 * 300, 'Check if timeEntry can count its own cost');

is($t->cost, 0.5*300 + 1*300 + 0.5*300 + 0.17*300 + 1.0*200 + 2.0*300 + 1.0*100 + 2.5*25 + 0.15*200 + 1.5*300 + 0.2*100 + 0.1*25 + 0.1*25 + 0.2 * 25 + 0.3*25 + 8*300 + 6*300 + 0.5*100 + 0.7*15 + 6.0*50 + 6.0*200 + 4.0 * 100 + 2.6*50 + 7.3*300 + 0.89*300, 'Check if timeEntry list can count total cost'); # зато надежно


