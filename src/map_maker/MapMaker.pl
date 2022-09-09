#!/usr/bin/perl

use strict;
use warnings; 

use feature qw(say);

BEGIN {
    push @INC, "./";
}

use Log::Log4perl qw(:easy);
use Data::Dumper;

use MapMaker::Screen;
use MapMaker::UserInput;
use MapMaker::Map;

use constant {
    CURSOR_DEFAULT => "+",
    CURSOR_HORIZONTAL_MAX => 81,
    CURSOR_HORIZONTAL_MIN => 1,
    CURSOR_VERTICAL_MAX => 22,
    CURSOR_VERTICAL_MIN => 2
};

Log::Log4perl->init('./MapMaker/conf/log4perl.conf');

my $log = Log::Log4perl->get_logger("MapMaker");

my $scr = MapMaker::Screen->new(use_term_colors => 1);
my $inp = MapMaker::UserInput->new(screen => $scr->{screen});
my $map = MapMaker::Map->new(screen => $scr);

# TODO : load from cmd arg if exists or via load in app.
my $map_filename = "../server/RpgServer/data/maps/0_1_0.map";
$map->load_map_data($map_filename);

redraw_screen();

my %cursor_info = (
    x => 40,
    y => 10,
    old_x => 41,
    old_y => 10,
    cursor => CURSOR_DEFAULT
);

my %new_tile = (
    x => 0, 
    y => 0, 
    fg_color => 0,
    bg_color => 0,
    char => ' ',
    attr => 0
);

my $frame = 0;

$scr->echo(0);
$scr->set_cursor($cursor_info{x}, $cursor_info{y});


my $quit = 0;
do {

    my $delta_x = 0;
    my $delta_y = 0;

    my $user_inp = $inp->getch;
    if ($user_inp eq "w") {
        $delta_y--;
    } elsif ($user_inp eq "s") {
        $delta_y++;
    } elsif ($user_inp eq "a") {
        $delta_x--;
    } elsif ($user_inp eq "d") {
        $delta_x++;
    } elsif ($user_inp eq "q") {
        $quit = 1;
    } elsif ($user_inp eq "t") {
        setup_new_tile(\%new_tile);
    }


    if ($delta_x != 0 || $delta_y != 0) {

        my $attempted_x = $cursor_info{x} + $delta_x;
        my $attempted_y = $cursor_info{y} + $delta_y;

        if (is_in_bounds($attempted_x, $attempted_y)) {            
            $cursor_info{old_x} = $cursor_info{x};
            $cursor_info{old_y} = $cursor_info{y};
            $cursor_info{x} += $delta_x;
            $cursor_info{y} += $delta_y;

            my %tile = $map->get_tile_hash_at_cursor($cursor_info{old_x}, $cursor_info{old_y});         
            $scr->draw_tile(%tile);
        }

    }

   # $scr->set_cursor($cursor_info{x}, $cursor_info{y});
   # $scr->draw($cursor_info{x}, $cursor_info{y}, $cursor_info{cursor}, 15, $map->get_background_color($cursor_info{x} - 1, $cursor_info{y} - 2));

    my %tile = $map->get_tile_hash_at_cursor($cursor_info{x}, $cursor_info{y});

    $scr->draw_repeat(95, 3, " ", 0, 0, 20);
    $scr->set_cursor(95, 3);    
    say "Cur x/y: " . $cursor_info{x} . "/" . $cursor_info{y};
        

    $scr->clear_line(24);
    $scr->set_cursor(1, 24);
    say "TILE X,Y: (" . $tile{x} . "," . $tile{y} . ") CHAR: " . $tile{char} . " FG: " . $tile{fg_color} . " BG : " . $tile{bg_color} . " ATTR: " . $tile{attr};

    $scr->clear_line(25);
    $scr->set_cursor(1, 25);
    say "NEW TILE X,Y: (" . $new_tile{x} . "," . $new_tile{y} . ") CHAR: " . $new_tile{char} . " FG: " . $new_tile{fg_color} . " BG : " . $new_tile{bg_color} . " ATTR: " . $new_tile{attr};

    $frame++;
    if ($frame > 1) {
        $frame = 0;        
        if ($cursor_info{cursor} eq CURSOR_DEFAULT) {
            $cursor_info{cursor} = $tile{char};
        } else {
            $cursor_info{cursor} = CURSOR_DEFAULT;
        }
    }

    $tile{fg_color} = 15;
    $tile{char} = $cursor_info{cursor};
    $scr->draw_tile(%tile);
     
   
} while (!$quit);


$scr->refresh;

say "Bye!";
exit;


sub redraw_screen {

    my %screen_size = $scr->get_screen_size;

    # draw title bar
    $scr->refresh;
    $scr->draw_repeat(0, 0, " ", 15, 22, $screen_size{x});
    $scr->draw((($screen_size{x} / 2) - 4), 0, "Map Maker", 15, 22);

    # draw map draw area border
    $scr->draw(0, 1, "┌────────────────────────────────────────────────────────────────────────────────┐", 15, 0);
    for my $row (1 .. 21) {
        $scr->draw(0, 1 + $row, "│", 15, 0);
        $scr->draw(81, 1 + $row, "│", 15, 0);
    }
    $scr->draw(0, 22, "└────────────────────────────────────────────────────────────────────────────────┘", 15, 0);

    $map->draw_map;

    $scr->set_cursor(1, 23);
    say "MAP FILENAME: $map_filename";
}


sub setup_new_tile {
    my ($new_tile) = @_;

    # draw map draw area border
    $scr->draw(15, 4, "╔═══Configure New Tile═════════════════════╗", 0, 7);
    for my $row (1 .. 10) {
        $scr->draw(15, 4 + $row, "║                                          ║▒", 0, 7);        
    }
    $scr->draw(15, 15, "╚══════════════════════════════════════════╝▒", 0, 7);
    $scr->draw(16, 16, "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒", 0, 7);

    $scr->draw(24, 6, "Character:", 0, 7);
    $scr->draw(17, 7, "Foreground Color:", 0, 7);
    $scr->draw(17, 8, "Background Color:", 0, 7);
    $scr->draw(24, 9, "Attribute:", 0, 7);

    $scr->set_cursor(35, 6);
    $scr->echo(1);
    
    my $new_char = $inp->blocking_getch;
    if ($new_char eq "") {
        $new_char = " ";
    }
    
    
    my $fg_color;
    my $fg_valid = 0;
    do { 
        
        $scr->draw(15, 7, "║                                          ║▒", 0, 7);   
        $scr->draw(17, 7, "Foreground Color:", 0, 7);

        $scr->set_cursor(35, 7);
        $fg_color = $inp->get_string_input;        

        if ($fg_color !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } elsif ($fg_color < 0 || $fg_color > 255) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } else {
            $fg_valid = 1;
        }
    } while (!$fg_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    $scr->draw(40, 7, $new_char, $fg_color, 0);

    my $bg_color;
    my $bg_valid = 0;
    do { 
        
        $scr->draw(15, 8, "║                                          ║▒", 0, 7);   
        $scr->draw(17, 8, "Background Color:", 0, 7);

        $scr->set_cursor(35, 8);
        $bg_color = $inp->get_string_input;        

        if ($bg_color !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } elsif ($bg_color < 0 || $bg_color > 255) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } else {
            $bg_valid = 1;
        }
    } while (!$bg_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    $scr->draw(40, 8, $new_char, $fg_color, $bg_color);


    my $attr;
    my $attr_valid = 0;
    do { 
        
        $scr->draw(15, 9, "║                                          ║▒", 0, 7);   
        $scr->draw(24, 9, "Attribute:", 0, 7);

        $scr->set_cursor(35, 9);
        $attr = $inp->get_string_input;        

        if ($attr !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } elsif ($attr < 0 || $attr > 255) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } else {
            $attr_valid = 1;
        }
    } while (!$attr_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    $scr->draw(40, 9, $map->get_attribute_name($attr), 0, 7, 1);


    $scr->draw(25, 11, "New Tile: ", 0, 7);
    $scr->draw(35, 11, $new_char, $fg_color, $bg_color);
    $scr->draw(20, 12, "Use these settings [y/n]", 0, 7, 1);

    my $confirm = $inp->blocking_getch;
    if (lc($confirm) eq 'y') {        
        $new_tile->{char} = $new_char;
        $new_tile->{fg_color} = $fg_color;
        $new_tile->{bg_color} = $bg_color;
        $new_tile->{attr} = $attr;
        
        $log->info("Set new tile config to: " . Dumper \$new_tile);
    }

    redraw_screen();
}



sub is_in_bounds {
    my ($x, $y) = @_;

    if ($y < CURSOR_VERTICAL_MIN || $y >= CURSOR_VERTICAL_MAX) {
        $log->info("not in bounds: $x, $y");
        return 0;
    }
    if ($x < CURSOR_HORIZONTAL_MIN || $x >= CURSOR_HORIZONTAL_MAX) {
        $log->info("not in bounds: $x, $y");
        return 0;
    }
    return 1;

}