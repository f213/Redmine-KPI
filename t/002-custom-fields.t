#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

use Redmine::KPI::Element::CustomFields;

my $f = new Redmine::KPI::Element::CustomFields;

$f->add(
	id	=> 1,
	name	=> 'testF1',
	value	=> '',
);
$f->add(
	id	=> 2,
	name	=> 'testF2',
	value	=> 'val2',
);
$f->add(
	id	=> 3,
	name	=> 'Русский',
	value	=> 'язык',
);

is($f->getValue('tEstf2'), 'val2', 'Finding value in custom fields by name');
is($f->getValue(2), 'val2', 'Finding value in custom fields by id');
is($f->getValue('Русский'), 'язык', 'Finding value by name (unicode)');
