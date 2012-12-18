package Redmine::KPI::Query::Projects;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl		=> sub {'projects.xml'},
		_nodesName	=> sub {'projects/project'},
		_elemName	=> sub {'project'},
	},
;

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->_nodesName))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('redmineId',		$_->findvalue('identifier'));
		$self->{list}{$id}->param('description',	$_->findvalue('description'));
	}
}
1;
