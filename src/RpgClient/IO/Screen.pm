#!/usr/bin/perl

package RpgClient::IO::Screen;

require Term::Screen;

use feature qw(say);
use Moo;


has screen => (
    is => 'rwp'
);

sub BUILD {
    my ($self, $ags) = @_;
    my $scr = Term::Screen->new();
    unless ($scr) { die "Something when wrong $!\n"; }
    $self->_set_screen($scr);
    $self->screen->noecho;
}


sub refresh {
    my $self = shift;
    $self->screen->clrscr();
}


sub draw {
    my ($self, $x, $y, $text) = @_;
    $self->screen->at($y, $x);
    $self->screen->puts($text);
    # $scr->at(10, 6)->bold()->puts("hi!")->normal();
}


1;
