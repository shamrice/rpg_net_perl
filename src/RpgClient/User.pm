#!/usr/bin/perl
package RpgClient::User;

use Data::UUID;
use feature qw(say);
use Moo;

use constant {
    STATUS_ALIVE =>    "ALIVE   ",
    STATUS_DEAD =>     "DEAD    ",
    STATUS_POISONED => "POISONED"
};

has name => (
    is => 'rw',
    required => 1
);

has user_char => (
    is => 'rw',
    required => 1
);

has x => (
    is => 'rw',
    default => int(rand(79)) + 1
);

has y => (
    is => 'rw',
    default => int(rand(19)) + 1
);

has map_x => (
    is => 'rw',
    default => 0
);

has map_y => (
    is => 'rw',
    default => 0
);

has needs_redraw => (
    is => 'rw',
    default => 1
);

has is_active => (
    is => 'rw',
    default => 1
);

has old_x => (
    is => 'rwp',
    default => 0
);

has old_y => (
    is => 'rwp',
    default => 0
);

has id => (
    is => 'rwp'
);

has max_hp => (
    is => 'rwp'
);

has current_hp => (
    is => 'rwp'
);

has status => (
    is => 'rwp'
);



sub BUILD {
    my ($self, $args) = @_;
    if (length($self->user_char) > 1) {
        $self->user_char(substr($self->user_char, 0, 1));
    }

    my $ug = Data::UUID->new;
    my $user_id_raw = $ug->create_from_name($ug->create, (localtime().$ug->create()));
    my $user_id = $ug->to_string($user_id_raw);

    $self->_set_id($user_id);

    my $start_hp = 10;
    $self->_set_max_hp($start_hp);
    $self->_set_current_hp($start_hp);

    $self->_set_status(STATUS_ALIVE);

    # say "Created new user with id: $user_id and user_char: $user_char";

}

sub move {
    my ($self, $x_delta, $y_delta) = @_;
    $self->_set_old_x($self->x);
    $self->_set_old_y($self->y);    
    $self->x($self->x + $x_delta);
    $self->y($self->y + $y_delta);
    $self->needs_redraw(1);
    $self->is_active(1);
}

sub undo_move {
    my $self = shift;

    my $new_old_x = $self->x;
    my $new_old_y = $self->y;
    $self->x($self->old_x);
    $self->y($self->old_y);
    $self->_set_old_x($new_old_x);
    $self->_set_old_y($new_old_y);
    $self->needs_redraw(1);
    $self->is_active(1);
}

sub get_position {
    my $self = shift;
    my @position = ($self->x, $self->y);    
    return @position;
}


sub get_stats {
    my $self = shift;

    my %stats = (
        current_hp => $self->current_hp,
        max_hp => $self->max_hp,
        status => $self->status
    );

    return %stats;
}

sub update_health {
    my ($self, $health_delta) = @_;

    $self->_set_current_hp($self->current_hp + $health_delta);
    if ($self->current_hp <= 0) {
        $self->_set_status(STATUS_DEAD);
        $self->_set_current_hp(0);
    }
}

sub is_alive {
    my $self = shift;
    return $self->status eq STATUS_ALIVE;
}

1;