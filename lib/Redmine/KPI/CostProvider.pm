#!/usr/bin/perl
package Redmine::KPI::CostProvider;
use Badger::Class
	base	=> 'Badger::Base',
;

sub init
{
	(my $self, my $config) = @_;
	$self->{config} = $config;
	
	foreach (qw/users trackers activities/)
	{
		if(exists $self->{config}{$_})
		{
			$self->__parseInput($_, $self->{config}{$_});
			undef $self->{config}{$_};
		}
	}

	$self->__parseInput('activities', $self->{config}); # by default keys are activity names (this was the old format of costProvider)

	$self;
}

sub cost
{
	my $self = shift;
	my $timeEntry = shift;

	$self->error('This method needs instance of timeEntry') if !$timeEntry->isa('Redmine::KPI::Element::TimeEntry');

	my $time	= $timeEntry->param('hours');

	return $time * $self->_entryCost($timeEntry);
}

sub _entryCost
{
	my $self = shift;
	my $timeEntry = shift;

	my %act;

	$act{id} 		= $timeEntry->param('activity')->param('id');
	$act{name}		= $timeEntry->param('activity')->param('name');
	
	my $result = $self->__findPrice('activities', $act{id}, $act{name});

	if(exists($self->{trackers}))
	{
		my %tracker;
		$tracker{id}	= $timeEntry->param('issue')->param('tracker')->param('id');
		$tracker{name}	= $timeEntry->param('issue')->param('tracker')->param('name');

		$result *= $self->__findPrice('trackers', $tracker{id}, $tracker{name});
	}
	if(exists($self->{users}))
	{
		my %user;
		$user{id}	= $timeEntry->param('user')->param('id');
		$user{name}	= $timeEntry->param('user')->param('name');

		$result *= $self->__findPrice('users', $user{id}, $user{name});
	}

	return $result;
}

sub __findPrice
{
	my $self = shift;
	my $attrName = shift;
	(my $id, my $name) = @_;

	$self->fatal('no activities found') if not exists $self->{$attrName} and $attrName eq 'activities'; # Когда задана активность без цены, или не задана вообще, то лучше пусть упадет ошибка, чем будут теряться деньги

	return 1 if not exists $self->{$attrName};

	return $self->{$attrName}{$id} if exists $self->{$attrName}{$id}; # first, try to search by id

	foreach(grep {!/^\d+$/} keys %{ $self->{$attrName} }) # and then by name. grep is here to not check digital (id) costs
	{
		return $self->{$attrName}{$_} if /^$name$/i;
	}
	
	$self->fatal('unknown activity given') if $attrName eq 'activities';

	return 1;
}



sub __parseInput
{
	my $self = shift;
	my $attrName = shift;
	my $a = shift;

	foreach (keys %{ $a })
	{
		my $key = $_;
		foreach(split /\:/)
		{
			$self->{$attrName}{$_} = $a->{$key};
		}
	}
}

1;
