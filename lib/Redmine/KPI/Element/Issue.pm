package Redmine::KPI::Element::Issue;
use Badger::Class
	base 		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		_paramsToFetch	=> sub { qw /priority status author assignedTo start_date due_date done_ratio estimated_hours/ },
	},
;

our @FETCH_URL_PARAMETERS = qw /children relations changesets/;

sub _getUrl
{
	my $self = shift;
	my $url = 'issues/' . $self->param('id') . '.xml';

	if(@FETCH_URL_PARAMETERS)
	{
		$url.='?include=' . join ',', @FETCH_URL_PARAMETERS;
	}
	return $url;
}

sub _parse
{
	my $self = shift;
	
	($self->{rootNode}) = $self->{xml}->findnodes('issue');
	
	$self->__addStdParam($_) foreach qw /priority project status author assigned_to/;

	$self->param('description',	$self->{rootNode}->findvalue('description'));

	$self->__fetchChangeSets();
	1;
}
sub __addStdParam
{
	my $self = shift;
	my $paramName = shift;
	my $xmlParamName = $paramName;

	$paramName =~ s/_(.{0,1})/uc($1)/eg; #redmine snakecase to our camelcase

	$self->_elementFactory($paramName,
		id	=> $self->{rootNode}->findvalue("$xmlParamName/\@id"),
		name	=> $self->{rootNode}->findvalue("$xmlParamName/\@name"),
	);
}
sub __fetchChangeSets
{
	my $self = shift;

	my %cs;

	foreach($self->{rootNode}->findnodes('changesets/changeset'))
	{
		my $id = $_->getAttribute('revision');
		$cs{$id} = $self->{elemFactory}->element('changeset',
			id		=> $id,
			comments	=> $_->findvalue('comments'),
			commitedOn	=> $_->findvalue('committed_on'),
			user		=> $self->{elemFactory}->element('author',
					id	=> $_->findvalue('user/@id'),
					name	=> $_->findvalue('user/@name'),
			),
		);


	}
	$self->param('changesets', \%cs);
}


1;
