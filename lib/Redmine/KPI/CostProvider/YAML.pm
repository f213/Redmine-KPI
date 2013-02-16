package Redmine::KPI::CostProvider::YAML;
use strict;
use warnings;
use utf8;
use Redmine::KPI::CostProvider;
use YAML::Tiny;
use Carp;

sub create
{
	my $file = shift;
	
	confess "Cannot open input file" unless -f $file;

	my $yaml = YAML::Tiny->read($file);

	return Redmine::KPI::CostProvider->new($yaml->[0]);
}

1;
