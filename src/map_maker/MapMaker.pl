#!/usr/bin/perl

use strict;
use warnings; 

use feature qw(say);

BEGIN {
    push @INC, "./";
}

use Log::Log4perl qw(:easy);

use MapMaker::Screen;
use MapMaker::UserInput;
use MapMaker::Map;

Log::Log4perl->init('../client/RpgClient/conf/log4perl.conf');

my $scr = MapMaker::Screen->new(use_term_colors => 1);
my $inp = MapMaker::UserInput->new(screen => $scr);
my $map = MapMaker::Map->new(screen => $scr);

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

# TODO : load from cmd arg if exists or via load in app.
$map->load_map_data("../server/RpgServer/data/maps/0_1_0.map");
$map->draw_map;

$scr->set_cursor(0, 25);