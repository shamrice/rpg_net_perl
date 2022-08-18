#!/usr/bin/perl

package RpgClient::Map;

use feature qw(say);

use Moo;

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
        0 => '.',
        1 => '|'
    };

}

sub set_map_data {
    my ($self, $map_data_raw) = @_;

    my @map_rows = split("!", $map_data_raw);
    my $map_y = 0;
    foreach my $row (@map_rows) {
        # say "Row = $row";        
        my @row_data = split(/\|/, $row);        
        # say "Row data = @row_data";
        my $map_x = 0;
        foreach my $x_data (@row_data) {
            # say "x b = $x_data";
            my ($draw_value, $attr_value) = split(",", $x_data);
            # say "dv av = $draw_value $attr_value";
            $self->{map_data}->{$map_y}{$map_x} = {
                tile_id => $draw_value,
                attr => $attr_value
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

            $self->screen->draw($x, $y, $tile);           
        }
    }
}

sub get_tile {
    my ($self, $x, $y) = @_;

    my $sizeof_y = keys %{$self->{map_data}};
    my $sizeof_x = keys %{$self->{map_data}{0}};

    if ($x >= $sizeof_x || $y >= $sizeof_y) {
        return undef;
    }

    my $tile_id = $self->{map_data}->{$y}{$x}{tile_id};
    my $tile = $self->map_tile_lookup->{$tile_id};

    return $tile;
}

1;
