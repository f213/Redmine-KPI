package Redmine::KPI::Element::Tracker;
use Badger::Class
        base    => 'Redmine::KPI::Element::Base',
        methods => {
                issues                  => sub { my $self = shift; $self->_queryFactory('issues', tracker => $self->param('id'), @_) },
        },
;

1;
