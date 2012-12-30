#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More tests => 2;

use Redmine::KPI::Query::Users;

my $u = Redmine::KPI::Query::Users->new(
	xml		=> 't/fixtures/users.xml',
	customFields	=> {
		4	=> 1,
	},
);
#is($u->count, 1, 'Check if text filter by login works');

is($u->count, 1, 'Check if custom field filter by id works');


$u = Redmine::KPI::Query::Users->new(
	xml		=> 't/fixtures/users.xml',
	customFields	=> {
		'Исполнитель задач'	=> 1,
	},
);
is($u->count, 1, 'Check if custom field filter by name works');

