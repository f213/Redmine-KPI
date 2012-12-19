#!/usr/bin/perl
package Redmine::KPI::CostProvider;
use Badger::Class
	base	=> 'Badger::Base',
;

sub init
{
	(my $self, my $config) = @_;
	$self->{config} = $config;

	foreach(keys %{$self->{config}})
	{
		my $key = $_;
		foreach(split /\:/)
		{
			$self->{costs}{$_} = $self->{config}{$key};
		}
	}

	$self;
}

sub cost
{
	my $self = shift;
	my $timeEntry = shift;

	$self->error('Method need instance of timeEntry') if ref($timeEntry) ne 'Redmine::KPI::Element::TimeEntry';

	my $id 		= $timeEntry->param('activity')->param('id');
	my $name	= $timeEntry->param('activity')->param('name');
	my $time	= $timeEntry->param('hours');

	return $time * $self->{costs}{$id}	if exists $self->{costs}{$id};  # at first trying to find activity by id

	foreach(grep {!/^\d+$/} keys %{ $self->{costs} }) # and then by name. grep is here to not check digital (id) costs
	{
		return $time * $self->{costs}{$_} if /^$name$/i;
	}
	return 0;
}
1;
