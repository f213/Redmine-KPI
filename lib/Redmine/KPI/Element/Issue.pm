package Redmine::KPI::Element::Issue;
use Badger::Class
	base 		=> 'Redmine::KPI::Element::Base',
	methods		=> {
		_paramsToFetch	=> sub { qw /description subject priority status author assignedTo start_date due_date done_ratio estimated_hours relatedToMe relatedFromMe children relations parent/ },
		timeEntries	=> sub { shift->__queryFactory('timeEntries', @_) },
	},
;
use utf8;
our @FETCH_URL_PARAMETERS = qw /children relations changesets/;

sub cost
{
	my $self = shift;

	$self->timeEntries(@_)->cost;
}

sub _getUrl
{
	my $self = shift;
	my $url = 'issues/' . $self->param('id') . '.xml' if $self->param('id');

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
	
	$self->_addStdParam($_) foreach qw /priority project status author assigned_to/;

	$self->param('description',	$self->{rootNode}->findvalue('description'));
	$self->param('subject',		$self->{rootNode}->findvalue('subject'));

	$self->__fetchParent();
	
	$self->__fetchRelations();

	$self->__fetchChangeSets();
	1;
}


sub __fetchRelations
{
	my $self = shift;

	return if not $self->param('id');

	my @toMe;
	foreach($self->{rootNode}->findnodes('relations/relation[@issue_to_id = "' . $self->param('id') . '"]'))
	{
		push @toMe, $_->getAttribute('issue_id');
	}
	$self->param('relatedToMe', $self->_queryFactory('issues', issue => \@toMe )) if @toMe;

	my @fromMe;
	foreach($self->{rootNode}->findnodes('relations/relation[@relation_type="relates" and @issue_id = "' . $self->param('id') . '"]'))
	{
		push @fromMe, $_->getAttribute('issue_to_id');
	}
	$self->param('relatedFromMe', $self->_queryFactory('issues', issue => \@fromMe )) if @fromMe;

	my @children;

	foreach($self->{rootNode}->findnodes('children/issue'))
	{
		push @children, $_->getAttribute('id');
	}
	$self->param('children', $self->_queryFactory('issues', issue => \@children )) if @children;

	my @relates = (@fromMe, @toMe);
	$self->param('relations', $self->_queryFactory('issues', issue => \@relates )) if @relates;

}

sub __fetchChangeSets
{
	my $self = shift;

	my %cs;

	foreach($self->{rootNode}->findnodes('changesets/changeset'))
	{
		my $id = $_->getAttribute('revision');
		$cs{$id} = $self->_elementFactory('changeset',
			id		=> $id,
			comments	=> $_->findvalue('comments'),
			commitedOn	=> $_->findvalue('committed_on'),
			user		=> $self->_elementFactory('author',
					id	=> $_->findvalue('user/@id'),
					name	=> $_->findvalue('user/@name'),
			),
		);


	}
	$self->param('changesets', \%cs);
}
sub __fetchParent
{
	my $self = shift;

	my $parentId = $self->{rootNode}->findvalue('parent/@id');
	if($parentId)
	{
		$self->param('parent', $self->_elementFactory('issue',
				id	=> $parentId,
				@_,
			)
		);
	}
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
