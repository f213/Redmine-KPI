#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use_ok('Redmine::KPI::Element::Issue');

use Redmine::KPI::Element::Base;

my $el = Redmine::KPI::Element::Issue->new(
	id	=> 100501,
	url	=> 'http://redmine.shogo.ru',
);

is($el->param('id'), 100501, 'Setting ID parameter via constructor');
$el->param('id1', 100500);
is($el->param('id1'), 100500, 'Getting\setting parameters');


