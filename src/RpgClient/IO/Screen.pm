#!/usr/bin/perl

package RpgClient::IO::Screen;

require Term::Screen;

use feature qw(say);
use Moo;

use constant {
    TERMINAL_COLOR_PREFIX => "\033[",
    TERMINAL_COLOR_SUFFIX => "m",
    TERMINAL_COLOR_RESET => "\033[0m"
};

=pod 
    Terminal escape sequence reference: https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
=cut

has screen => (
    is => 'rwp'
);


has use_term_colors => (
    is => 'ro',
    default => 0
);

has color_map => (
    is => 'rwp'
);

sub BUILD {
    my ($self, $ags) = @_;
    my $scr = Term::Screen->new();
    unless ($scr) { die "Something when wrong $!\n"; }
    $self->_set_screen($scr);
    $self->screen->noecho;

    my %color_map = (
        FG_BLACK => 30,
        FG_RED => 31,
        FG_GREEN => 32,
        FG_YELLOW => 33,
        FG_BLUE => 34,
        FG_MAGENTA => 35,
        FG_CYAN => 36,
        FG_WHITE => 37,
        FG_BRIGHT_BLACK => 90,
        FG_BRIGHT_RED => 91,
        FG_BRIGHT_GREEN => 92,
        FG_BRIGHT_YELLOW => 93,
        FG_BRIGHT_BLUE => 94,
        FG_BRIGHT_MAGENTA => 95,
        FG_BRIGHT_CYAN => 96,
        FG_BRIGHT_WHITE => 97,

        BG_BLACK => 40,
        BG_RED => 41,
        BG_GREEN => 42,
        BG_YELLOW => 43,
        BG_BLUE => 44,
        BG_MAGENTA => 45,
        BG_CYAN => 46,
        BG_WHITE => 47,
        BG_BRIGHT_BLACK => 100,
        BG_BRIGHT_RED => 101,
        BG_BRIGHT_GREEN => 102,
        BG_BRIGHT_YELLOW => 103,
        BG_BRIGHT_BLUE => 104,
        BG_BRIGHT_MAGENTA => 105,
        BG_BRIGHT_CYAN => 106,
        BG_BRIGHT_WHITE => 107,
        
    );

    $self->_set_color_map(\%color_map);
}


sub refresh {
    my $self = shift;
    $self->screen->clrscr();
}


sub draw {

    # TODO : Use ANSI color codes to display text in color provided. 

    my ($self, $x, $y, $text, $fg_color, $bg_color) = @_;

    $self->screen->at($y, $x);    

    if ($self->use_term_colors) {
        if (not defined $fg_color) {
            $fg_color = $self->color_map->{FG_WHITE};
        }
        if (not defined $bg_color) {
            $bg_color = $self->color_map->{BG_BLACK};
        }
        my $color_str = TERMINAL_COLOR_PREFIX . $fg_color . ";" . $bg_color . TERMINAL_COLOR_SUFFIX;

        $self->screen->puts($color_str.$text.TERMINAL_COLOR_RESET);

    } else {
        $self->screen->puts($text);
    }


    
    
    # $scr->at(10, 6)->bold()->puts("hi!")->normal();
}


1;
