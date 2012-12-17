#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Redmine::KPI' ) || print "Bail out!
";
}

diag( "Testing Redmine::KPI $Redmine::KPI::VERSION, Perl $], $^X" );
