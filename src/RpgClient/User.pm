#!/usr/bin/perl
package RpgClient::User;

use Data::UUID;
use feature qw(say);
use Moo;

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
    default => int(rand(80)) + 1
);

has y => (
    is => 'rw',
    default => int(rand(20)) + 1
);

has needs_redraw => (
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


sub BUILD {
    my ($self, $args) = @_;
    if (length($self->user_char) > 1) {
        $self->user_char(substr($self->user_char, 0, 1));
    }

    my $ug = Data::UUID->new;
    my $user_id_raw = $ug->create_from_name($ug->create, (localtime().$ug->create()));
    my $user_id = $ug->to_string($user_id_raw);

    $self->_set_id($user_id);

    # say "Created new user with id: $user_id and user_char: $user_char";

}

sub move {
    my ($self, $x_delta, $y_delta) = @_;
    $self->{old_x} = $self->{x};
    $self->{old_y} = $self->{y};
    $self->{x} += $x_delta;
    $self->{y} += $y_delta;
    $self->{needs_redraw} = 1;
}

sub get_position {
    my $self = shift;
    my @position = ($self->{x}, $self->{y});    
    return @position;
}

1;