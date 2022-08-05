#!/usr/bin/perl
package RpgClient::IO::UserInput;

# use Term::ReadKey;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $screen = shift;
    my $self = { screen => $screen };
    bless $self, $class;
}

sub blocking_getch {
    my $self = shift;
    my $char = $self->{screen}->getch;
    return $char;
}

sub getch {
    my $self = shift;

    my $char = ""; 
    if ($self->{screen}->key_pressed(0.1)) {        
        $char = $self->{screen}->getch;
    }
    return $char;
}


1;
