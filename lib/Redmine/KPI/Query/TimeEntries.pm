package Redmine::KPI::Query::TimeEntries;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl		=> sub {'time_entries.xml'},
		_nodesName	=> sub {'time_entries/time_entry'},
		_elemName	=> sub {'timeEntry'},
		_limit		=> sub {1000},
		_stdFilters	=> sub {qw/tracker project issue activity user/},
		_stdParams	=> sub {qw/project issue user activity/},
	},
;
use POSIX qw /ceil/;
use Class::Date qw /date/;

sub totalTime
{
	my $self = shift;

	my $t;
	$t += $self->{list}{$_}->param('hours') foreach keys %{$self->{list}};

	return $t;
}


sub _init
{
	my $self = shift;
	
	if($self->{config}{period})
	{
		# some note about 'date' magic: when we use Class::Date date('2012-12-21') is equal to date(date('2012-12-21')) so user can pass scalar parsable date or instance of Class::Date object
		if(ref($self->{config}{period}) eq 'ARRAY') # double dates given
		{
			our @period = @{ $self->{config}{period} };
			$self->_addFilter(
				local	=> 'spentOn',
				value	=> sub
					{
						my $spentDate = date($_[0]);
						return 0 if $spentDate < date($period[0]) or $spentDate > date($period[1]);
						1;
					},
			);

		}
		else
		{ # single date given - scalar or instance of Class::Date
			$self->_addFilter(
				local	=> 'spentOn',
				value	=> $self->{config}{period},
			);
		}

	}
	1;
}

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->_nodesName))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('hours',	$_->findvalue('hours'));
		$self->{list}{$id}->param('spentOn',	date( $_->findvalue('spent_on' ) ));
	}

	$self->__formatHours();
}

sub __formatHours
{
	my $self = shift;

	foreach(keys %{ $self->{list} })
	{
		my $h = $self->{list}{$_}->param('hours');

		$h *= 1; #type

		if(exists $self->{config}{roundHours} and $self->{config}{roundHours})
		{
			$h = ceil($h);
		}
		if(exists $self->{config}{minHours} and $self->{config}{minHours})
		{
			$h = $self->{config}{minHours} if $h < $self->{config}{minHours};
		}
		$self->{list}{$_}->param('hours', $h);
	}
}
1;
