#!/usr/bin/perl

package RpgClient::Map;

use feature qw(say);

use Moo;

use constant {
    TILE_ID_KEY => "tile_id",
    TILE_ATTRIBUTE_KEY => "attr",

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


sub handle_map_interaction {
    my ($self, $user) = @_;
    my $attr = $self->get_attribute($user->x, $user->y);
    
    if (not defined $attr) {
        return;
    }

    if ($attr == TILE_ATTRIBUTE_BLOCKING) {
        $user->undo_move;
    } elsif ($attr == TILE_ATTRIBUTE_HURT) {
        $user->update_health(-2); # magic numbers for now...
    }

}

1;
