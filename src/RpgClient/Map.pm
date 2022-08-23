#!/usr/bin/perl

package RpgClient::Map;

use feature qw(say);
use Compress::LZW;
use MIME::Base64;

use Moo;

use constant {
    TILE_ID_KEY => "tile_id",
    TILE_ATTRIBUTE_KEY => "attr",
    TILE_FOREGROUND_COLOR_KEY => "fg_color",
    TILE_BACKGROUND_COLOR_KEY => "bg_color",

    TILE_ATTRIBUTE_BLOCKING => 1,
    TILE_ATTRIBUTE_HURT => 2
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
    my $map_data_raw = decode_base64($map_data_raw);
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
}

sub draw_map {
    my $self = shift;

    foreach my $y (keys %{$self->{map_data}}) {
        foreach my $x (keys %{$self->{map_data}{0}}) {
            
            my $tile_id = $self->{map_data}->{$y}{$x}{tile_id};
            my $tile = $self->map_tile_lookup->{$tile_id};

            my $fg_color = $self->{map_data}->{$y}{$x}{fg_color};
            my $bg_color = $self->{map_data}->{$y}{$x}{bg_color};

            $self->screen->draw($x, $y, $tile, $fg_color, $bg_color);           
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

    my $sizeof_y = keys %{$self->{map_data}};
    my $sizeof_x = keys %{$self->{map_data}{0}};

    if ($x >= $sizeof_x || $y >= $sizeof_y) {
        return undef;
    }

    my $tile_data = $self->{map_data}->{$y}{$x}{$tile_key};    

    return $tile_data;
}


=pod
    Handles user interactions with the map at their x,y coordinates.
    Returns: true on blocking interaction otherwise, returns 1.
=cut;
sub handle_map_interaction {
    my ($self, $user) = @_;
    my $attr = $self->get_attribute($user->x, $user->y);
    
    if (not defined $attr) {
        return 0;
    }

    if ($attr == TILE_ATTRIBUTE_BLOCKING) {
        $user->undo_move;
        return 1;
    } elsif ($attr == TILE_ATTRIBUTE_HURT) {
        $user->update_health(-2); # magic numbers for now...
    }
    return 0;
}

1;
