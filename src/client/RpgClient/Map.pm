#!/usr/bin/perl

package RpgClient::Map;

use feature qw(say);
use Compress::LZW;
use MIME::Base64;
use Data::Dumper;
use Carp;

use Moo;

use constant {
    MAP_VERTICAL_MAX => 20,
    MAP_HORIZONTAL_MAX => 80,

    TILE_ID_KEY => "tile_id",
    TILE_ATTRIBUTE_KEY => "attr",
    TILE_FOREGROUND_COLOR_KEY => "fg_color",
    TILE_BACKGROUND_COLOR_KEY => "bg_color",

    TILE_ATTRIBUTE_BLOCKING => 1,
    TILE_ATTRIBUTE_HURT => 2,
    TILE_ATTRIBUTE_DEATH => 3
};

has screen => (
    is => 'ro',
    required => 1
);

has map_data => (
    is => 'rwp',
);

has map_tile_lookup => (
    is => 'rwp'
);

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("RpgClient") }
);


sub BUILD {
    my ($self, $args) = @_;

    # TODO : load from a config? 
    $self->{map_tile_lookup} = {
        0 => ' ',
        1 => '|',
        2 => '^'
    };

}

sub set_map_data {
    my ($self, $map_data_raw) = @_;

    # map data is base64 encoded & LZW compressed. Need to convert to raw string data.
    $map_data_raw = decode_base64($map_data_raw);
    $map_data_raw = decompress($map_data_raw);

    my @map_rows = split("!", $map_data_raw);
    my $map_y = 0;
    foreach my $row (@map_rows) {
        # say "Row = $row";        
        my @row_data = split(/\|/, $row);        
        # say "Row data = @row_data";
        my $map_x = 0;
        foreach my $x_data (@row_data) {
            # say "x b = $x_data";
            my ($draw_value, $attr_value, $fg_color, $bg_color) = split(",", $x_data);
            # say "dv av = $draw_value $attr_value";
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
    $self->logger->info("Finished setting map data.");
}

sub draw_map {
    my $self = shift;

    foreach my $y (keys %{$self->{map_data}}) {
        foreach my $x (keys %{$self->{map_data}{0}}) {
            
            my $tile_id = $self->{map_data}->{$y}{$x}{tile_id};

            #if for some reason tile_id is called at an unset x,y. die with confession.
            if (defined $tile_id) {
                my $tile = $self->map_tile_lookup->{$tile_id};

                my $fg_color = $self->{map_data}->{$y}{$x}{fg_color};
                my $bg_color = $self->{map_data}->{$y}{$x}{bg_color};

                $self->screen->draw($x, $y, $tile, $fg_color, $bg_color);           
            } else {
                my $key_str = "";
                foreach my $key (keys %{$self->{map_data}}) {
                    $key_str .= " $key,";
                }
                $self->logger->logconfess("TILE ID NOT DEFINED AT: $y,$x Y keys=$key_str : map_data=" . Dumper \$self->{map_data});
            }
        }
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

sub get_tile {
    my ($self, $x, $y) = @_;
    my $tile_id = $self->get_tile_data($x, $y, TILE_ID_KEY);
    return $self->map_tile_lookup->{$tile_id};
}

sub get_attribute {
    my ($self, $x, $y) = @_;
    return $self->get_tile_data($x, $y, TILE_ATTRIBUTE_KEY);
}

sub get_tile_data {
    my ($self, $x, $y, $tile_key) = @_;

    # don't call out of bounds or will cause autovivication of that invalid range. Hard stop for now.
    if ($y < 0 || $y > MAP_VERTICAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds y tile at: $x, $y");
    }
    if ($x < 0 || $x > MAP_HORIZONTAL_MAX) {
        $self->logger->logconfess("Attempted to get out of bounds x tile at: $x, $y");
    }

    my $sizeof_y = keys %{$self->{map_data}};
    my $sizeof_x = keys %{$self->{map_data}{0}};

    if ($x >= $sizeof_x || $y >= $sizeof_y) {
        return;
    }

    my $tile_data = $self->{map_data}->{$y}{$x}{$tile_key};    

    return $tile_data;
}


=pod
    TODO: Code smell updating user in the map module...
    Handles user interactions with the map at their x,y coordinates.
    Returns: true on blocking interaction otherwise, returns 1.
=cut
sub handle_map_interaction {
    my ($self, $user) = @_;

    if ($user->y >= MAP_VERTICAL_MAX) {
        $user->map_y($user->map_y + 1);
        $user->y(1);
        #$user->_set_old_y(1);
        $user->needs_map_load(1);
        return 0;
    } elsif ($user->y < 0) {
        $user->map_y($user->map_y - 1);
        $user->y(MAP_VERTICAL_MAX - 2);
        #$user->_set_old_y(MAP_VERTICAL_MAX - 2);
        $user->needs_map_load(1);
        return 0;
    } elsif ($user->x >= MAP_HORIZONTAL_MAX) {
        $user->map_x($user->map_x + 1);
        $user->x(1);        
        $user->needs_map_load(1);
        return 0;
    } elsif ($user->x < 0) {
        $user->map_x($user->map_x - 1);
        $user->x(MAP_HORIZONTAL_MAX - 2);        
        $user->needs_map_load(1);
        return 0;
    } 
    
    my $attr = $self->get_attribute($user->x, $user->y);
    
    if (not defined $attr) {
        return 0;
    }

    if ($attr == TILE_ATTRIBUTE_BLOCKING) {
        $user->undo_move;
        return 1;
    } elsif ($attr == TILE_ATTRIBUTE_HURT) {
        $user->update_health(-2); # magic numbers for now...
    } elsif ($attr == TILE_ATTRIBUTE_DEATH) {
        $user->update_health(-999999); # magic numbers for now...
    }
    return 0;
}

1;
