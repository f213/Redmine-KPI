package Redmine::KPI::Fetch;
use Badger::Class base => 'Class::Singleton';
use File::Slurp;
use Carp;
require Crypt::SSLeay;
require IO::Socket::SSL;
#TODO - totaly rewrite this from scratch!
sub fetch
{
	(my $self, my $whatToFetch, my $apiKey, my $param) = @_;
	
	if(ref($whatToFetch) eq 'Rose::URI')
	{
		confess('we need authKey param') if not $apiKey or not length $apiKey;
		my $ua = new LWP::UserAgent;

		$ua->ssl_opts(verify_hostname=>0, SSL_verify_mode => 0x00 ) if exists $param->{noVerifyHost} and $param->{noVerifyHost} and $ua->can('ssl_opts'); # old versions of LWP::UserAgent dont need this. if it can not set ssl_options, it does not verify host name, AFAIK

		$ua->default_header(
			'X-Redmine-API-Key' => $apiKey,
		);

		my $r = $ua->get($whatToFetch->as_string);
		$self->error($r->status_line, $whatToFetch) if($r->is_error);
		return $r->content;
	}
	else
	{
		$self->error("There is no such file: '$whatToFetch'") if not -e $whatToFetch;
		my $f = read_file($whatToFetch) or $self->error('Could not fetch file!', $whatToFetch);
		return $f;
	}
}
sub error
{
	my $self = shift;
	confess "$_[0] at url '$_[1]";
}

1;



