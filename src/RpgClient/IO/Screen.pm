#!/usr/bin/perl

package RpgClient::IO::Screen;

require Term::Screen;

use feature qw(say);
use Moo;


use constant {
    TERMINAL_COLOR_PREFIX => "\033[",
    TERMINAL_COLOR_FG_START => "38;5;",
    TERMINAL_COLOR_BG_START => "48;5;",
    TERMINAL_COLOR_SUFFIX => "m",
    TERMINAL_COLOR_RESET => "\033[0m"
};

=pod 
    Terminal escape sequence reference: 
        https://en.wikipedia.org/wiki/ANSI_escape_code
        https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
=cut

has screen => (
    is => 'rwp'
);


has use_term_colors => (
    is => 'ro',
    default => 0
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
    my ($self, $x, $y, $text, $fg_color, $bg_color) = @_;

    if (not defined $text) {
        return;
    }

    $self->screen->at($y, $x);    

    if ($self->use_term_colors) {
        if (not defined $fg_color) {
            $fg_color = 7; 
        } 
        if (not defined $bg_color) {
            $bg_color = 0; 
        } 
        my $color_str = TERMINAL_COLOR_PREFIX . 
            TERMINAL_COLOR_FG_START . $fg_color . ";" . 
            TERMINAL_COLOR_BG_START . $bg_color . 
            TERMINAL_COLOR_SUFFIX;

        $self->screen->puts($color_str.$text.TERMINAL_COLOR_RESET);

    } else {
        $self->screen->puts($text);
    }
    
    # $scr->at(10, 6)->bold()->puts("hi!")->normal();
}


1;
