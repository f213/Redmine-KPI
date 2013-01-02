package Redmine::KPI;
use utf8;
use Badger::Class
	base		=> 'Badger::Base',
	mutators	=> '_cacheCodec _queryFactory',
	methods		=> {
		user		=> sub {shift->somewhat		('users', 	@_)},
		users		=> sub {shift->somewhats	('users', 	@_)},
		issue		=> sub {shift->somewhat		('issues', 	@_)},
		issues		=> sub {shift->somewhats	('issues', 	@_)},
		tracker		=> sub {shift->somewhat		('trackers', 	@_)},
		trackers	=> sub {shift->somewhats	('trackers',	@_)},
		project		=> sub {shift->somewhat		('projects',	@_)},
		projects	=> sub {shift->somewhats	('projects',	@_)},
	},
;
use Redmine::KPI::Query::Factory;
use Redmine::KPI::Config;
use Redmine::KPI::CostProvider;
use Badger::Codec::Base64;

=head1 NAME

Redmine::KPI - The great new Redmine::KPI!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub init
{
	(my $self, my $config) = @_;

	$self->{config} = $config;
	$self->_cacheCodec(new Badger::Codec::Base64);
	$self->_queryFactory(new Redmine::KPI::Query::Factory);
	$self;
}
sub somewhat
{
	my $self = shift;
	my $name = shift;

	my $result = $self->somewhats($name)->find(@_);
	$result->query if $result and exists $self->{config}{autoFetch} and $self->{config}{autoFetch};
	return $result;
	
}
sub somewhats
{
	my $self = shift;
	my $name = shift;
	my $cacheKey = $self->_cacheCodec->encode($name, @_);
	#TODO write less dumb cache implementation, this is a stub!
	return $self->{cache}{$cacheKey} if exists $self->{cache}{$cacheKey};

	$self->{cache}{$cacheKey} = $self->_queryFactory->query($name, passConfigParams($self->{config}, @_));
;
}
sub costProvider
{
	my $self = shift;

	return Redmine::KPI::CostProvider->new(@_);
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Redmine::KPI;

    my $foo = Redmine::KPI->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

=head2 function2

=cut

=head1 AUTHOR

Fedor A Borshev, C<< <fedor at shogo.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-redmine-kpi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Redmine-KPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Redmine::KPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Redmine-KPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Redmine-KPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Redmine-KPI>

=item * Search CPAN

L<http://search.cpan.org/dist/Redmine-KPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fedor A Borshev.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Redmine::KPI
