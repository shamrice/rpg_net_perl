#!/usr/bin/perl
package RpgClient::IO::UserInput;

use Moo;

has screen => (
    is => 'ro'
);

sub blocking_getch {
    my $self = shift;
    my $char = $self->screen->getch;
    return $char;
}

sub getch {
    my $self = shift;

    my $char = ""; 
    if ($self->screen->key_pressed(0.1)) {        
        $char = $self->screen->getch;
    }
    return $char;
}


1;
