#!/usr/bin/perl
use strict;
use warnings; 
use feature qw(say);

use Log::Log4perl qw(:easy);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use FindBin;

use lib "$FindBin::Bin/";

use MapMaker::Screen;
use MapMaker::UserInput;
use MapMaker::Map;
use MapMaker::Enemy;


use constant {
    CURSOR_DEFAULT => "+",
    CURSOR_HORIZONTAL_MAX => 81,
    CURSOR_HORIZONTAL_MIN => 1,
    CURSOR_VERTICAL_MAX => 22,
    CURSOR_VERTICAL_MIN => 2
};

my $help;
my $log_config_file = "$FindBin::Bin/MapMaker/conf/log4perl.conf";
my $map_filename = ""; # "../server/RpgServer/data/maps/0_1_0.map"; # TODO : should make blank to trigger new map

GetOptions(
    "log=s" => \$log_config_file,
    "file=s" => \$map_filename,        
    "help|?" => \$help         
) or pod2usage(2);

pod2usage(0) if $help;

Log::Log4perl->init($log_config_file);

my $log = Log::Log4perl->get_logger("MapMaker");

my $scr = MapMaker::Screen->new(use_term_colors => 1);
my $inp = MapMaker::UserInput->new(screen => $scr->{screen});
my $map = MapMaker::Map->new(screen => $scr);
# my $enemy = MapMaker::Enemy->new();

if ($map_filename ne "") {
    $map->load_map_data($map_filename);
} else {
    $map->new_map();
}

if (!$map->are_coordinates_set) {
    set_map_coordinates();
}

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

my %new_enemy = (
    x => 0,
    y => 0,
    name => "UNSET",
    user_char => "?",
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
    } elsif ($user_inp eq "e") {
        place_new_enemy($cursor_info{x}, $cursor_info{y});
    } elsif ($user_inp eq "E") {
        setup_new_enemy();
    } elsif ($user_inp eq "n") {
        create_new_map();
    } elsif ($user_inp eq "o") {
        load_existing_map();
    } elsif ($user_inp eq "p") {
        set_map_coordinates();
    } elsif ($user_inp eq "q") {
        $quit = confirm_quit();
    } elsif ($user_inp eq "t") {
        setup_new_tile(\%new_tile);
    } elsif ($user_inp eq " ") {
        $new_tile{x} = $cursor_info{x} - 1;
        $new_tile{y} = $cursor_info{y} - 2;
        $map->set_tile(%new_tile);
        $scr->draw_tile(%new_tile);
    } elsif ($user_inp eq '$') {
        save_current_map();        
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

            # draw enemy if was placed on top of tile walked on.
            my $enemy_token = $map->enemies->get_enemy_at_cursor($cursor_info{old_x}, $cursor_info{old_y});
            if (defined $enemy_token) {
                $tile{char} = $enemy_token;
                $tile{fg_color} = 15;
            }

            $scr->draw_tile(%tile);
        }

    }

    my %tile = $map->get_tile_hash_at_cursor($cursor_info{x}, $cursor_info{y});

    $scr->draw_repeat(95, 3, " ", 0, 0, 20);
    $scr->set_cursor(95, 3);    
    say "Cur x/y: " . $cursor_info{x} . "/" . $cursor_info{y};
        

    $scr->clear_line(24);
    $scr->set_cursor(1, 24);
    say "TILE X,Y: (" . $tile{x} . "," . $tile{y} . ") CHAR: " . $tile{char} . " FG: " . $tile{fg_color} . " BG : " . $tile{bg_color} . " ATTR: " . $tile{attr};

    $scr->clear_line(25);
    $scr->set_cursor(1, 25);

    $scr->draw(1, 25, 
        "NEW TILE CHAR:   FG: " . 
        $new_tile{fg_color} . 
        " BG : " . $new_tile{bg_color} . 
        " ATTR: " . $new_tile{attr} .
        " (" . $map->get_attribute_name($new_tile{attr}) . ")",
        7, 0
    );    
    $scr->draw(16, 25, $new_tile{char}, $new_tile{fg_color}, $new_tile{bg_color});    
    

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
     
   
} until ($quit);


$scr->refresh;

say "Bye!";
exit;



sub set_map_coordinates {
    $scr->draw_window(
        x => 10,
        y => 5,
        width => 40, 
        height => 8,
        fg_color => 0,
        bg_color => 7,
        title => "Set Map Coordinates"        
    );

    if ($map->are_coordinates_set) {    
        $scr->draw(12, 6, 
            "Current coordinates: " . 
            $map->map_coordinates->{world_id} . "," .
            $map->map_coordinates->{map_x} . "," .
            $map->map_coordinates->{map_y},
            2, 7, 1
        );
    } else {
        $scr->draw(16, 6, "Map coordinates not yet set!", 1, 7, 1);
    }

    $scr->draw(12, 8, "Enter new value? [y/N]", 0, 7);
    my $confirm = lc($inp->blocking_getch());
    if ($confirm ne "y") {
        redraw_screen();
        return;
    }

    $scr->draw(12, 10, "Enter w,x,y coordinates: ____________", 0, 7);
    my $coords_valid;
    my $new_coords = "";
    do {
        $scr->set_cursor(37, 10);
        $new_coords = $inp->get_string_input();
        $coords_valid = $new_coords =~ m/^\d+,\d+,\d+$/;
        if (!$coords_valid) {
            $scr->draw(37, 10, "____________", 0, 7);
            $scr->draw(20, 11, "Not valid coordinates", 1, 7, 1);
        }
    } until ($coords_valid);

    my ($world_id, $map_x, $map_y) = split(/,/, $new_coords);

    $map->set_map_coordinates($world_id, $map_x, $map_y);

    redraw_screen();
}



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


sub confirm_quit {
    $scr->draw_window(
        x => 15,
        y => 10,
        width => 40, 
        height => 4,
        fg_color => 0,
        bg_color => 7,
        title => "Quit"        
    );
          #15, 10, 40, 4, 0, 7, "Quit");
    $scr->draw(17, 12, "Are you sure you want to quit? [y/N]: ", 0, 7);
    my $confirm = lc($inp->blocking_getch());
    
    redraw_screen();

    if ($confirm eq 'y') {
        return 1;
    } 
    return 0;

}


sub load_existing_map {

    $scr->draw_window(
        x => 20,
        y => 5,
        width => 30, 
        height => 4,
        fg_color => 0,
        bg_color => 7,
        title => "Load Map"        
    );
        #20, 5, 30, 4, 0, 7, "Load Map");

    $scr->draw(22, 7, "File name: __________________", 0, 7);
    $scr->set_cursor(33, 7);
    my $filename = $inp->get_string_input();

    if ($filename ne "") {
        $map->load_map_data($filename);
        $scr->draw(32, 8, "Loaded!", 2, 7, 1);
        $inp->blocking_getch();
    } else {
        $scr->draw(28, 8, "Map not loaded", 1, 7, 1);
        $inp->blocking_getch();
    }

    redraw_screen();
}


sub save_current_map {

    $scr->draw_window(
        x => 20,
        y => 5,
        width => 30, 
        height => 6,
        fg_color => 0,
        bg_color => 7,
        title => "Save Map"        
    );
        #20, 5, 30, 6, 0, 7, "Save Map");
    $scr->draw(25, 7, "Save current map? [y/N]:", 0, 7);
    my $confirm = lc($inp->blocking_getch());
    if ($confirm eq "y") {
        $scr->draw(25, 8, "File name: _______________", 0, 7);
        $scr->set_cursor(36, 8);
        my $filename = $inp->get_string_input();

        if ($map->save_map_data($filename)) {
            $scr->draw(32, 10, "Saved!", 2, 7, 1);
            $inp->blocking_getch();
        } else {
            $scr->draw(27, 10, "Failed to save map.", 1, 7, 1);
            $inp->blocking_getch();
        }
    }
    redraw_screen();
;
}


sub create_new_map {
    $scr->draw_window(
        x => 20,
        y => 10,
        width => 25,
        height => 4,
        fg_color => 0,
        bg_color => 7,
        title => "New Map"        
    );

        #20, 10, 25, 4, 0, 7, "New Map");
    $scr->draw(22, 12, "Start new map? [y/N]: ", 0, 7);
    my $confirm = lc($inp->blocking_getch());
    if ($confirm eq 'y') {
        $map->new_map();
    } 
    set_map_coordinates();
    redraw_screen();
}


sub setup_new_tile {
    my ($new_tile) = @_;

    $scr->draw_window(
        x => 15,
        y => 4,
        width => 41, 
        height => 12,
        fg_color => 0,
        bg_color => 7,
        title => "Configure New Tile"        
    );
        #15, 4, 41, 12, 0, 7, "Configure New Tile");

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
    } until ($fg_valid);

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
    } until ($bg_valid);

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
    } until ($attr_valid);

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


sub setup_new_enemy {

    $scr->draw_window(
        x => 15,
        y => 4,
        width => 41, 
        height => 10,
        fg_color => 0,
        bg_color => 7,
        title => "Configure Enemy"        
    );
    

    $scr->draw(24, 6, "Character:", 0, 7); 
    $scr->draw(23, 7, "Enemy Name:", 0, 7);   
    $scr->draw(23, 8, "Hit Points:", 0, 7);
    $scr->draw(20, 9, "Attack Damage:", 0, 7);
    $scr->draw(23, 10, "Attributes: ", 0, 7);

    $scr->set_cursor(35, 6);
    $scr->echo(1);
    
    my $new_char = $inp->blocking_getch;
    if ($new_char eq "") {
        $new_char = " ";
    }
    
    my $name;
    my $name_valid = 0;
    do {         

        $scr->draw(15, 7, "║                                          ║▒", 0, 7);
        $scr->draw(23, 7, "Enemy Name:", 0, 7);

        $scr->set_cursor(35, 7);

        $name = $inp->get_string_input;
        if ($name !~ m/^\s*$/) {
            $name_valid = 1;
            $name = uc($name);
        } else {
            $scr->draw(20, 11, "Please enter a name", 1, 7, 1);        
        }

    } until ($name_valid);
    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    

    my $hp;
    my $hp_valid = 0;
    do { 
        
        $scr->draw(15, 8, "║                                          ║▒", 0, 7);   
        $scr->draw(23, 8, "Hit Points:", 0, 7);

        $scr->set_cursor(35, 8);
        $hp = $inp->get_string_input;        

        if ($hp !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number > 0", 1, 7, 1);        
        } elsif ($hp < 0) {
            $scr->draw(20, 11, "Please enter a number > 0", 1, 7, 1);        
        } else {
            $hp_valid = 1;
        }
    } until ($hp_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   

    my $atk;
    my $atk_valid = 0;
    do { 
        
        $scr->draw(15, 9, "║                                          ║▒", 0, 7);   
        $scr->draw(20, 9, "Attack Damage:", 0, 7);

        $scr->set_cursor(35, 9);
        $atk = $inp->get_string_input;        

        if ($atk !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number > 0", 1, 7, 1);        
        } elsif ($atk < 0) {
            $scr->draw(20, 11, "Please enter a number > 0", 1, 7, 1);        
        } else {
            $atk_valid = 1;
        }
    } until ($atk_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    


    my $attr;
    my $attr_valid = 0;
    do { 
        
        $scr->draw(15, 10, "║                                          ║▒", 0, 7);   
        $scr->draw(23, 10, "Attributes:", 0, 7);

        $scr->set_cursor(35, 10);
        $attr = $inp->get_string_input;        

        if ($attr !~ m/^[0-9]+$/) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } elsif ($attr < 0 || $attr > 255) {
            $scr->draw(20, 11, "Please enter a number between 0-255", 1, 7, 1);        
        } else {
            $attr_valid = 1;
        }
    } until ($attr_valid);

    $scr->draw(15, 11, "║                                          ║▒", 0, 7);   
    
    $scr->draw(20, 12, "Use these settings [y/n]", 0, 7, 1);
    my $confirm = $inp->blocking_getch;

    if (lc($confirm) eq "y") {
        $new_enemy{user_char} = $new_char;
        $new_enemy{name} = $name;
        $new_enemy{hp} = $hp;
        $new_enemy{atk} = $atk;
        $new_enemy{attr} = $attr;
        $log->info("Setting enemy settings..." . Dumper \%new_enemy);
    }


    redraw_screen();
}


sub place_new_enemy {
    my ($x, $y) = @_;

    $new_enemy{x} = $x;
    $new_enemy{y} = $y;

    $map->enemies->add_enemy(%new_enemy);    
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




__END__
 
=head1 NAME
 
MapMaker - Utility for creating map data
 
=head1 SYNOPSIS
 
MapMaker [options] 
 
 Options:
   --help           display help and exit
   --file           load file at start up
   --log            specify log config file (Default ./MapMaker/conf/log4perl.conf)

