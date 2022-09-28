package MapMaker::Map;

use feature qw(say);
use Compress::LZW;
use MIME::Base64;
use Data::Dumper;
use Carp;

use Moo;

use MapMaker::Enemy;

use constant {
    MAP_VERTICAL_MAX => 20,
    MAP_HORIZONTAL_MAX => 80,

    TILE_ID_KEY => "tile_id",
    TILE_ATTRIBUTE_KEY => "attr",
    TILE_FOREGROUND_COLOR_KEY => "fg_color",
    TILE_BACKGROUND_COLOR_KEY => "bg_color",

    TILE_ATTRIBUTE_NONE => 0,
    TILE_ATTRIBUTE_BLOCKING => 1,
    TILE_ATTRIBUTE_HURT => 2,
    TILE_ATTRIBUTE_DEATH => 3,

    TILE_BLANK => 32
};

has screen => (
    is => 'ro',
    required => 1
);

has map_data => (
    is => 'rwp',
);

has map_coordinates => (
    is => 'rwp'
);

has are_coordinates_set => (
    is => 'rw',
    default => 0
);

has enemies => (
    is => 'ro', 
    default => sub { MapMaker::Enemy->new; }   
);

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("MapMaker") }
);


sub set_map_coordinates {
    my ($self, $world_id, $map_x, $map_y) = @_;

    $self->_set_map_coordinates({
        world_id => $world_id,
        map_x => $map_x,
        map_y => $map_y
    });

    $self->enemies->update_world_location($world_id, $map_x, $map_y);

    $self->are_coordinates_set(1);
    $self->logger->info("Updated map coordinates to: " . Dumper \$self->{map_coordinates});
}


sub new_map {
    my $self = shift;    

    foreach my $map_y (0..MAP_VERTICAL_MAX - 1) {
        foreach my $map_x (0..MAP_HORIZONTAL_MAX - 1) {
            $self->{map_data}->{$map_y}{$map_x} = {
                tile_id => TILE_BLANK,
                attr => TILE_ATTRIBUTE_NONE,
                fg_color => 0,
                bg_color => 0
            };   
        }
    }
    $self->are_coordinates_set(0);
    $self->logger->info("Set up new blank map data.");
    
}

sub save_map_data {
    my ($self, $map_file_name) = @_;

    if ($map_file_name eq "") {
        return;
    }

    if (!$self->are_coordinates_set) {
        $self->logger->info("Map coordinates not set. Cannot save map.");
        return;
    }


    open(my $MAP_FH, '>', $map_file_name) or do {
        $self->logger->error("Failed to open output map file: $map_file_name :: $!");
        return;
    };

    # Save enemy data if map output was able to be opened.
    (my $enemy_file_name = $map_file_name) =~ s/\.map/-enemy\.json/;
    return unless $self->enemies->save_enemy_data($enemy_file_name);


    my $map_coordinates_line = "#LOCATION=" . 
        $self->map_coordinates->{world_id} . "," . 
        $self->map_coordinates->{map_x} . "," . 
        $self->map_coordinates->{map_y} . "\n";
    
    print $MAP_FH $map_coordinates_line;


    foreach my $row (0..MAP_VERTICAL_MAX - 1) {
        my $row_data = "";
        foreach my $column (0..MAP_HORIZONTAL_MAX - 1) { 
            $row_data .= $self->map_data->{$row}{$column}{tile_id} . 
                "," . 
                $self->map_data->{$row}{$column}{attr} . 
                "," . 
                $self->map_data->{$row}{$column}{fg_color} . 
                "," . 
                $self->map_data->{$row}{$column}{bg_color} .
                "|"            
        }
        $row_data .= "!";
        $self->logger->info($row_data);
        print $MAP_FH "$row_data\n";
    }

    close($MAP_FH);
    return 1;
}


sub load_map_data {
    my ($self, $map_file_name) = @_;

    # TODO : Return true/false on success failure instead of hard crashing.

    open(my $MAP_FH, '<', $map_file_name) or confess "Failed to open map file: $map_file_name :: $!";
    chomp(my @map_rows = <$MAP_FH>);
    close($MAP_FH);
    
    #load enemy data
    (my $enemy_file_name = $map_file_name) =~ s/\.map/-enemy\.json/;
    return unless $self->enemies->load_enemy_data($enemy_file_name);

    my $map_y = 0;
    foreach my $row (@map_rows) {
        $row =~ s/!//;

        # get location data if exists
        if ($row =~ m/^#LOCATION=\d*,\d*,\d*$/) {
            (my $location_str = $row) =~ s/^#LOCATION=//;
            my ($world_id, $map_x, $map_y) = split(/,/, $location_str);
            $self->logger->info("Found map location data :: world_id=$world_id : map_x=$map_x : map_y=$map_y");
            $self->set_map_coordinates($world_id, $map_x, $map_y);
        }

        # ignore comment rows
        if ($row =~ m/^#.*/) {
            next;
        }
        
        my @row_data = split(/\|/, $row);                
        my $map_x = 0;
        foreach my $x_data (@row_data) {            
            
            my ($draw_value, $attr_value, $fg_color, $bg_color) = split(",", $x_data);
            
            $self->{map_data}->{$map_y}{$map_x} = {
                tile_id => $draw_value,
                attr => $attr_value,
                fg_color => $fg_color,
                bg_color => $bg_color
            };        
            $map_x++;
        }
        $map_y++;
    }
    
    $self->logger->trace("Finished setting map data : " . Dumper \$self->{map_data});
}

sub draw_map {
    my $self = shift;

    foreach my $y (keys %{$self->map_data}) {
        foreach my $x (keys %{$self->map_data->{0}}) {
            
            my $tile_id = $self->map_data->{$y}{$x}{tile_id};

            #if for some reason tile_id is called at an unset x,y. die with confession.
            if (defined $tile_id) {
                my $tile = chr($tile_id); 

                my $fg_color = $self->map_data->{$y}{$x}{fg_color};
                my $bg_color = $self->map_data->{$y}{$x}{bg_color};

                $self->screen->draw($x + 1, $y + 2, $tile, $fg_color, $bg_color);           
            } else {
                my $key_str = "";
                foreach my $key (keys %{$self->map_data}) {
                    $key_str .= " $key,";
                }
                $self->logger->logconfess("TILE ID NOT DEFINED AT: $y,$x Y keys=$key_str : map_data=" . Dumper \$self->map_data);
            }
        }
    }


    my %enemies_to_draw = $self->enemies->enemy_hash->%*;
    foreach my $enemy_id (keys %enemies_to_draw) {
        $self->logger->info("Drawing enemy: " . Dumper \$enemies_to_draw{$enemy_id});
        my $bg_color = $self->get_background_color($enemies_to_draw{$enemy_id}{x}, $enemies_to_draw{$enemy_id}{y});
        $self->screen->draw($enemies_to_draw{$enemy_id}{x}, $enemies_to_draw{$enemy_id}{y}, $enemies_to_draw{$enemy_id}{user_char}, 15, $bg_color);
    }
}

sub get_background_color {
    my ($self, $x, $y) = @_;
    return $self->get_tile_data($x, $y, TILE_BACKGROUND_COLOR_KEY);
}

sub get_foreground_color {
    my ($self, $x, $y) = @_;
    return $self->get_tile_data($x, $y, TILE_FOREGROUND_COLOR_KEY);
}

sub set_tile {
    my ($self, %tile) = @_;

    $self->logger->info("Setting new tile: " . Dumper \%tile);
    $self->map_data->{$tile{y}}{$tile{x}}{tile_id} = ord($tile{char});
    $self->map_data->{$tile{y}}{$tile{x}}{attr} = $tile{attr};
    $self->map_data->{$tile{y}}{$tile{x}}{fg_color} = $tile{fg_color};
    $self->map_data->{$tile{y}}{$tile{x}}{bg_color} = $tile{bg_color};
}

sub get_tile {
    my ($self, $x, $y) = @_;
    my $tile_id = $self->get_tile_data($x, $y, TILE_ID_KEY);
    return chr($tile_id); 
}

sub get_attribute {
    my ($self, $x, $y) = @_;
    return $self->get_tile_data($x, $y, TILE_ATTRIBUTE_KEY);
}

sub get_tile_data {
    my ($self, $x, $y, $tile_key) = @_;

    # don't call out of bounds or will cause autovivication of that invalid range. Hard stop for now.
    if ($y < 0 || $y >= MAP_VERTICAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds y tile at: $x, $y");
    }
    if ($x < 0 || $x >= MAP_HORIZONTAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds x tile at: $x, $y");
    }

    my $sizeof_y = keys %{$self->map_data};
    my $sizeof_x = keys %{$self->map_data->{0}};

    if ($x >= $sizeof_x || $y >= $sizeof_y) {
        return;
    }

    my $tile_data = $self->map_data->{$y}{$x}{$tile_key};    

    return $tile_data;
}


sub get_tile_hash_at_cursor {
    my ($self, $x, $y) = @_;

    # compensate for the offset of the display location and the actual xy in memory.
    $x -= 1;
    $y -= 2;
    
    # don't call out of bounds or will cause autovivication of that invalid range. Hard stop for now.
    if ($y < 0 || $y >= MAP_VERTICAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds y tile at: $x, $y");
    }
    if ($x < 0 || $x >= MAP_HORIZONTAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds x tile at: $x, $y");
    }

    my $sizeof_y = keys %{$self->map_data};
    my $sizeof_x = keys %{$self->map_data->{0}};

    if ($x >= $sizeof_x || $y >= $sizeof_y) {
        return;
    }

    my $tile = $self->map_data->{$y}{$x};    

    # $self->logger->trace("Tile: " . Dumper \$tile);

    my %full_tile_info = (
        x => $x, 
        y => $y, 
        fg_color => $tile->{fg_color},
        bg_color => $tile->{bg_color},
        char => chr($tile->{tile_id}), # $self->map_tile_lookup->{$tile->{tile_id}},
        attr => $tile->{attr}
    );

    return %full_tile_info;

}


sub get_attribute_name {
    my ($self, $attribute_id) = @_;

    my $attribute_name = "UNKNOWN";

    if ($attribute_id == TILE_ATTRIBUTE_NONE) {
        $attribute_name = "NONE";
    } elsif ($attribute_id == TILE_ATTRIBUTE_DEATH) {
        $attribute_name = "DEATH";
    } elsif ($attribute_id == TILE_ATTRIBUTE_BLOCKING) {
        $attribute_name = "BLOCKING";
    } elsif ($attribute_id == TILE_ATTRIBUTE_HURT) {
        $attribute_name = "HURT";
    }

    return $attribute_name;
}

1;
