#!/usr/bin/perl

use strict;
use warnings; 

BEGIN {
    push @INC, "./";
}

use MapMaker::Screen;
use MapMaker::UserInput;

my $scr = MapMaker::Screen->new(use_term_colors => 1);
my $inp = MapMaker::UserInput->new(screen => $scr);

