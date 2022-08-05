#!/usr/bin/perl

package RpgClient::IO::Screen;

use feature qw(say);

use strict;
use warnings;

require Term::Screen;

sub new {
    my $class = shift;

    my $scr = Term::Screen->new();    
    unless ($scr) { die "Something went wrong $!\n"; }

    $scr->noecho;

    my $self = { screen => $scr };
    bless $self, $class;    
}

sub refresh {
    my $self = shift;
    $self->{screen}->clrscr();
}


sub draw {
    my ($self, $x, $y, $text) = @_;
    $self->{screen}->at($y, $x);
    $self->{screen}->puts($text);
    # $scr->at(10, 6)->bold()->puts("hi!")->normal();
}


1;
