#!/usr/bin/perl
package RpgClient::User;

use Data::UUID;
use feature qw(say);
use strict;
use warnings;


sub new {
    my ($class, $name, $user_char) = @_;
        
    if (not defined $user_char) {
        $user_char = "\$";
    }
    if (not defined $name) {
        $name = "NONAME";
    }

    chomp($name);
    chomp($user_char);

    if (length($user_char) > 1) {
        $user_char = substr($user_char, 0, 1);
    }

    my $ug = Data::UUID->new;
    my $user_id_raw = $ug->create_from_name($ug->create, (localtime().$ug->create()));
    my $user_id = $ug->to_string($user_id_raw);

    # say "Created new user with id: $user_id and user_char: $user_char";

    my $self = { 
        id => $user_id,
        name => $name,
        user_char => $user_char,
        x => int(rand(80)) + 1, # debug : random screen location to start
        y => int(rand(20)) + 1,
        needs_redraw => 1,
        old_x => 0,
        old_y => 0
    };
    bless $self, $class;
}

sub get_id {
    my $self = shift;
    return $self->{id};
}

sub get_name {
    my $self = shift;
    return $self->{name};
}

sub get_user_char {
    my $self = shift;
    return $self->{user_char};
}

sub get_x {
    my $self = shift;
    return $self->{x};
}

sub get_y {
    my $self = shift;
    return $self->{y};
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