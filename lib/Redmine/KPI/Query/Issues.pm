package Redmine::KPI::Query::Issues;
use Badger::Class
	base	=> 'Redmine::KPI::Query::Base',
	methods	=> {
		_getUrl		=> sub {'issues.xml'},
		_nodesName	=> sub {'issues/issue'},
		_elemName	=> sub {'issue'},
		_stdFilters	=> sub {qw /project tracker author/},
		_stdParams	=> sub {qw /project tracker author/},
	},
;
use Class::Date qw/date/;

sub _init
{
	my $self = shift;
	
	$self->{url}->query_param(status_id => '*'); #by default redmine passes only open queries. Destination of this module is statistics and reports, so we need all issues mostly. Fuck processor time economy!

	if(exists $self->{config}{period})
	{
		if(ref($self->{config}{period}) eq 'ARRAY')
		{
			our @period = @{ $self->{config}{period} };

			$self->_addFilter(
				get	=> 'created_on',
				value	=> '><'.join '|', @period,
			);
			$self->_addFilter(
				local	=> 'date',
				value	=> sub
					{
						return (date($_[0]) >= $period[0] and date($_[0]) <= $period[1]) ? 1: 0;
					}
			);
		}
		#TODO scalar and Class::Date parameters
	}
	1;
}

sub _updateList
{
	my $self = shift;

	foreach($self->xml->findnodes($self->_nodesName))
	{
		my $id = $_->findvalue('id');
		$self->{list}{$id}->param('name',	$_->findvalue('subject'));
		$self->{list}{$id}->param('date',	date ($_->findvalue('created_on')));


	}
}
1;
