package Redmine::KPI::Query::Users;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl		=> sub {'users.xml'},
		_nodesName	=> sub {'users/user'},
		_elemName	=> sub {'user'},
	},
;

sub _updateList
{
	my $self = shift;
	foreach($self->xml->findnodes($self->_nodesName))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('name', $_->findvalue('firstname') . ' ' . $_->findvalue('lastname') );
	}
}


1;
