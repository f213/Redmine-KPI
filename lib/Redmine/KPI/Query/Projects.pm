package Redmine::KPI::Query::Projects;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl	=> sub {'projects.xml'},
	},
;

sub _init
{
	my $self = shift;
	
	$self->{nodesNames} = 'projects/project';
	$self->{elemName} = 'project';
}

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->{nodesNames}))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('redmineId',		$_->findvalue('identifier'));
		$self->{list}{$id}->param('description',	$_->findvalue('description'));
	}
}
1;
