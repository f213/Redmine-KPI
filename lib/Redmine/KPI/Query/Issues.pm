package Redmine::KPI::Query::Issues;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl	=> 'issues.xml',
	},
;

sub _init
{
	my $self = shift;
	
	$self->{nodesNames} = 'issues/issue';
	$self->{elemName} = 'issue';

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

	1;
}

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->{nodesNames}))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('name',	$_->findvalue('subject'));
		$self->{list}{$id}->param('project',	$self->{elemFactory}->element('project',
				id	=> $_->findvalue('project/@id'),
				name	=> $_->findvalue('project/@name'),
			)
		);
		$self->{list}{$id}->param('tracker',	$self->{elemFactory}->element('tracker',
				id	=> $_->findvalue('tracker/@id'),
				name	=> $_->findvalue('tracker/@name'),
			)
		);

	}
}
1;
