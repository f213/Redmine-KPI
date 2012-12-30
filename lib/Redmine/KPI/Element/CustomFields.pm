#!/usr/bin/perl
package Redmine::KPI::Element::CustomFields;
use Badger::Class
	base	=> 'Badger::Base',
;

sub init
{
	my $self = shift;

	$self->{fields} = ();

	$self;
}
sub add
{
	my $self = shift;
	my %p = @_;
	my %field;
	$field{id}	= $p{id};
	$field{name}	= $p{name};
	$field{value}	= $p{value};
	push @{$self->{fields}}, \%field;

}
sub getValue
{
	(my $self, my $field) = @_;
	foreach ( @{ $self->{fields} } )
	{
		if($field =~ /^\d+$/)
		{
			return $_->{value} if $_->{id} eq $field;
		}
		else
		{
			return $_->{value} if $_->{name} =~ /^$field$/i;
		}
	}
}

1;
