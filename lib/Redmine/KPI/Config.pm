package Redmine::KPI::Config;
use strict;
use warnings;
use Exporter::Lite;


our @EXPORT	= qw / passConfigParams checkConfig/;

our @PARAMS_THAT_PASS_THRU = qw / url authKey dryRun minHours roundHours period costProvider/;


sub checkConfig
{
	my $elemName = shift;
	my $h = shift;

	if((not exists $h->{dryRun} or not $h->{dryRun}) and not exists $h->{$elemName}) # if someone passed class name with array to config, then there will be no checking, because there will be not any query
	{
		if(not exists $h->{xml} and not exists $h->{url})
		{
			return "You must give 'url' or 'xml' parameter!";
		}
		if(exists $h->{url})
		{
			if(not exists $h->{authKey})
			{
				return "You must give 'authKey' parameter together with url!";
			}
		}
	}
}

sub passConfigParams
{
	my $h = shift;
	my %r;
	foreach (@PARAMS_THAT_PASS_THRU)
	{
		$r{$_} = $h->{$_} if exists $h->{$_};
	}
	%r;
}
