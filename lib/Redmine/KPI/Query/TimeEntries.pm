package Redmine::KPI::Query::TimeEntries;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_limit	=> sub{1000},
		_getUrl	=> sub{'time_entries.xml'},
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
	
	$self->{nodesNames} = 'time_entries/time_entry';
	$self->{elemName} = 'timeEntry';

	if($self->{config}{projectId})
	{
		$self->_addFilter(
				get	=> 'project_id',
				local => 'project/id',
				value	=> $self->{config}{projectId},
		);
	}
	if($self->{config}{trackerId})
	{
		$self->_addFilter(
				get	=> 'tracker_id',
				local	=> 'tracker/id',
				value	=> $self->{config}{trackerId},
		);
	}
	if($self->{config}{issueId})
	{
		$self->_addFilter(
				get	=> 'issue_id',
				local	=> 'issue/id',
				value	=> $self->{config}{issueId},
		);
	}
	if($self->{config}{userId})
	{
		$self->_addFilter(
				get	=> 'user_id',
				local	=> 'user/id',
				value	=> $self->{config}{userId},
		);
	}
	if($self->{config}{period})
	{
		#some note about 'date' magic: when we use Class::Date date('2012-12-21') is equal to date(date('2012-12-21')) so user can pass scalar parsable date or instance of Class::Date object
		if(ref($self->{config}{period}) eq 'ARRAY') #double dates given
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
		{ #single date given - scalar or instance of Class::Date
			$self->_addFilter(
				local	=> 'spentOn',
				value	=> $self->{config}{period},
			);
		}

	}
	if($self->{config}{activity})
	{
		if($self->{config}{activity}=~/^\d+$/) #actvityId
		{
			$self->_addFilter(
				local	=> 'activity/id',
				value	=> $self->{config}{activity},
			);
		}
		else
		{
			our $name = $self->{config}{activity};
			$self->_addFilter(
				local	=> 'activity/name',
				value	=> sub
					{
						return 1 if($_[0] =~ /^$name$/i);
						0;
					}
			);
		}
	}
	1;
}

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->{nodesNames}))
	{
		my $node = $_;
		my $id = $node->findvalue('id');

		$self->__addStdParam($node, $_) foreach qw /project issue user activity/;

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


sub __addStdParam
{
	(my $self, my $node,  my $paramName) = @_;
	my $xmlParamName = $paramName;
	
	my $id = $node->findvalue('id');
	$paramName =~ s/_(.{0,1})/uc($1)/eg; #redmine snakecase to our camelcase

	$self->{list}{$id}->param($paramName,	$self->{elemFactory}->element($paramName,
			id	=> $node->findvalue("$xmlParamName/\@id"),
			name	=> $node->findvalue("$xmlParamName/\@name"),
		)
	);
}


1;
