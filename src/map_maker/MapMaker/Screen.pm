package MapMaker::Screen;

require Term::Screen;
use Term::Screen;
use feature qw(say);
use Moo;
use Data::Dumper;

# this is basically a copy/paste from the client code with some minor changes...

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

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("MapMaker") }
);


sub BUILD {
    my ($self, $ags) = @_;
    my $scr = Term::Screen->new();
    unless ($scr) { die "Something when wrong $!\n"; }
    $self->_set_screen($scr);
    $self->screen->curinvis;
    $self->screen->noecho;    
}


sub refresh {
    my $self = shift;
    $self->screen->clrscr();
}


sub clear_line {
    my ($self, $row) = @_;

    $self->screen->at($row, 1);
    $self->screen->clreos;
}

sub echo {
    my ($self, $enabled) = @_;
    if ($enabled) {
        $self->screen->curvis;
        $self->screen->echo;
    } else {
        $self->screen->curinvis;
        $self->screen->noecho;
    }
}


sub get_screen_size {
    my $self = shift;

    my %scr_size = (
        x => $self->screen->cols,
        y => $self->screen->rows
    );
    return %scr_size;
}

sub draw_repeat {
    my ($self, $x, $y, $char, $fg_color, $bg_color, $times) = @_;

    my $text = $char x $times; 
  
    $self->draw($x, $y, $text, $fg_color, $bg_color);
}


sub draw_tile {
    my ($self, %tile) = @_;

   # $self->logger->info("Received tile to draw: " . Dumper \%tile);

    $self->draw($tile{x} + 1, $tile{y} + 2, $tile{char}, $tile{fg_color}, $tile{bg_color});
  
    
}

sub draw {
    my ($self, $x, $y, $text, $fg_color, $bg_color, $is_bold) = @_;

    if (not defined $text) {
        return;
    }

    if ($is_bold) {
        $self->screen->bold;
    } else {
        $self->screen->normal;
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


sub set_cursor {
    my ($self, $x, $y) = @_;

    $self->screen->at($y, $x);
}


sub draw_window {
    my ($self, %window_attributes) = @_; # $x, $y, $width, $height, $fg_color, $bg_color, $title) = @_;

    # TODO : not sure how I feel about how this was hacked in from param list.
    my $x = $window_attributes{x};
    my $y = $window_attributes{y};
    my $width = $window_attributes{width};
    my $height = $window_attributes{height};
    my $fg_color = $window_attributes{fg_color};
    my $bg_color = $window_attributes{bg_color};
    my $title = $window_attributes{title};

    if (not defined $fg_color) {
        $fg_color = 0;
    }

    if (not defined $bg_color) {
        $bg_color = 7;
    }

    my $top_border = "╔";
    my $body_frame = "║";
    my $bottom_border = "╚";
    my $bottom_shadow = "";
    foreach my $cur_x (0..$width) {
        $top_border .= "═";
        $body_frame .= " ";
        $bottom_border .= "═";
        $bottom_shadow .= "▒";
    }
    $top_border .= "╗";
    $body_frame .= "║▒";
    $bottom_border .= "╝▒";
    $bottom_shadow .= "▒▒";
    
    $self->draw($x, $y, $top_border, $fg_color, $bg_color);

    if (defined $title) {
        $self->draw($x + 2, $y, $title, $fg_color, $bg_color);
    }

    for my $row (1 .. $height) {    
        $self->draw($x, $y + $row, $body_frame, $fg_color, $bg_color);
    }
    $self->draw($x, $y + $height, $bottom_border, $fg_color, $bg_color);
    $self->draw($x + 1, $y + $height + 1, $bottom_shadow, $fg_color, $bg_color);
}

1;
