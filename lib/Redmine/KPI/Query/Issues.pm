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
				value	=> '><'.join '|', @period, # http://www.redmine.org/projects/redmine/wiki/Rest_Issues
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

	# TODO maybe move this to the parent class
	if(exists $self->{config}{$self->_elemName}) # if we've got issue list, then we just dont do _query(), but insert issues into the list ourselves.
	{
		if(ref($self->{config}{$self->_elemName}) eq 'ARRAY')
		{
			foreach(@{ $self->{config}{$self->_elemName} })
			{
				$self->{list}{$_} = $self->_elementFactory($self->_elemName,
					id	=> $_,
				);
			}

			$self->{dryRun} = 1; # _query() will not be done

			$self->{count} = keys %{ $self->{list} }; #_updateList usualy does that, but we didn't run _query()
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
		$self->{list}{$id}->param('name',	$_->findvalue('subject'));
		$self->{list}{$id}->param('date',	date ($_->findvalue('created_on')));

	}

}
1;
