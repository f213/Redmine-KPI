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
	priority	=> 'Base',
	status		=> 'Base',
	changeset	=> 'ChangeSet',
};

1;

