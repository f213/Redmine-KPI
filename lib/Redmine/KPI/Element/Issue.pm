package Redmine::KPI::Element::Issue;
use Badger::Class
	base 		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		_paramsToFetch	=> sub { qw /priority status author assignedTo start_date due_date done_ratio estimated_hours relatedToMe relatedFromMe children relations parent/ },
		timeEntries	=> sub { shift->__queryFactory('timeEntries', @_) },
	},
;
use Redmine::KPI::Config; # we need this here because we are using $self->{queryFactory} directly sometimes, so we need to pass there config parameters

our @FETCH_URL_PARAMETERS = qw /children relations changesets/;

sub cost
{
	my $self = shift;

	$self->timeEntries(@_)->cost;
}

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

	$self->__fetchParent();
	
	$self->__fetchRelations();

	$self->__fetchChangeSets();
	1;
}
# TODO move this method to the base class
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


sub __fetchRelations
{
	my $self = shift;

	my @toMe;
	foreach($self->{rootNode}->findnodes('relations/relation[@issue_to_id = "' . $self->param('id') . '"]'))
	{
		push @toMe, $_->getAttribute('issue_id');
	}
	$self->param('relatedToMe', $self->{queryFactory}->query('issues', issue => \@toMe, passConfigParams($self->{config}))) if @toMe; #here we do not use method _queryFactory for bypassing its cache

	my @fromMe;
	foreach($self->{rootNode}->findnodes('relations/relation[@relation_type="relates" and @issue_id = "' . $self->param('id') . '"]'))
	{
		push @fromMe, $_->getAttribute('issue_to_id');
	}
	$self->param('relatedFromMe', $self->{queryFactory}->query('issues', issue => \@fromMe, passConfigParams($self->{config}), @_ )) if @fromMe;

	my @children;

	foreach($self->{rootNode}->findnodes('children/issue'))
	{
		push @children, $_->getAttribute('id');
	}
	$self->param('children', $self->{queryFactory}->query('issues', issue => \@children, passConfigParams($self->{config}), @_ )) if @children;

	my @relates = (@fromMe, @toMe);
	$self->param('relations', $self->{queryFactory}->query('issues', issue => \@relates, passConfigParams($self->{config}), @_ )) if @relates;

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
					passConfigParams($self->{config}),
					@_,
			),
		);


	}
	$self->param('changesets', \%cs);
}
sub __fetchParent
{
	my $self = shift;

	my $parentId = $self->{rootNode}->findvalue('parent/@id');

	$self->param('parent', $self->{elemFactory}->element('issue',
			id	=> $parentId,
			passConfigParams($self->{config}),
			@_,
		)
	);
}
sub __queryFactory
{
	my $self = shift;
	return $self->_queryFactory(shift,
		issue         => $self->param('id'),
		@_,
	);
}


1;
