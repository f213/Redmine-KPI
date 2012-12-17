package Redmine::KPI::Element::Factory;
use base Badger::Factory;
use strict;
use warnings;

our $ITEM 		= 'element';
our $ITEMS		= 'elements';
our $ELEMENT_PATH	= 'Redmine::KPI::Element';
our $ELEMENT_DEFAULT	= 'Std';


our $ELEMENT_NAMES = {
	author		=> 'User',
	assignedTo	=> 'User',
	priority	=> 'Std',
	tracker		=> 'Std',
	status		=> 'Std',
	timeEntry	=> 'Std',
	changeset	=> 'ChangeSet',
};

1;

