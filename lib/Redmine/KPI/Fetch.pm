package Redmine::KPI::Fetch;
use Badger::Class base => 'Class::Singleton';
use File::Slurp;


sub fetch
{
	(my $self, my $whatToFetch, my $apiKey) = @_;

	if(ref($whatToFetch) eq 'Rose::URI')
	{
		$self->decline('we need authKey param') if not $apiKey or not length $apiKey;
		my $ua = LWP::UserAgent->new();
		$ua->default_header(
			'X-Redmine-API-Key' => $apiKey,
		);
		my $r = $ua->get($whatToFetch->as_string);
		$self->error($r->status_line) if($r->is_error);
		return $r->content;
	}
	else
	{
		$self->error("There is no such file: '$whatToFetch'") if not -e $whatToFetch;
		my $f = read_file($whatToFetch) or $self->fatal('Could not fetch file!');
		return $f;
	}
}

1;



