package MapMaker::Enemy;

use Moo;
use Data::UUID;
use Data::Dumper;
use JSON;

has enemy_hash => (
    is => 'rwp',
    default => sub { $_ = {} }
);

has world_location => (
    is => 'rwp', 
    default => sub { $_ = {} }
);

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("MapMaker") }
);


sub update_world_location {
    my ($self, $new_world_id, $new_map_x, $new_map_y) = @_;

    if ($new_world_id < 0 || $new_map_x < 0 || $new_map_y < 0) {
        $self->log->error("Invalid new world coordinates for Enemies: $new_world_id, $new_map_x, $new_map_y");
        return;
    }

    $self->_set_world_location({
        world_id => $new_world_id,
        map_x => $new_map_x,
        map_y => $new_map_y
    });

    foreach my $enemy_id (keys $self->enemy_hash->%*) {
        $self->enemy_hash->{$enemy_id}{world_id} = $new_world_id;
        $self->enemy_hash->{$enemy_id}{map_x} = $new_map_x;
        $self->enemy_hash->{$enemy_id}{map_y} = $new_map_y;
    }

    $self->logger->info("Updated enemies in hash with new world location: " . Dumper \$self->world_location);

}


sub add_enemy {
    my ($self, %enemy_info) = @_;

    $self->logger->info("New enemy: " . Dumper \%enemy_info);

    #todo : validate enemy info hash is valid.

    my $ug = Data::UUID->new;
    my $user_id_raw = $ug->create_from_name($ug->create, (localtime().$ug->create()));
    my $enemy_id = "ENEMY-" . $ug->to_string($user_id_raw);

    $enemy_info{id} = $enemy_id;
    $enemy_info{world_id} = $self->world_location->{world_id};
    $enemy_info{map_x} = $self->world_location->{map_x};
    $enemy_info{map_y} = $self->world_location->{map_y};

    

    $self->{enemy_hash}->{$enemy_info{id}} = {%enemy_info};

    $self->logger->info("Current enemy array: " . Dumper \$self->enemy_hash);
}


sub get_enemy_at_cursor {
    my ($self, $x, $y) = @_;

    #compensate for map display offset.
    #$x -= 1;
    #$y -= 2;
    
    foreach my $enemy_id (keys $self->enemy_hash->%*) {

        # $self->logger->info("Checking enemy id: $enemy_id DUMP: " . Dumper \$self->enemy_hash->{$enemy_id});

        if ($self->enemy_hash->{$enemy_id}{x} == $x && $self->enemy_hash->{$enemy_id}{y} == $y) {
            $self->logger->debug("FOUND ENEMY! " . Dumper \$self->enemy_hash->{$enemy_id});
            return $self->enemy_hash->{$enemy_id}{user_char};
        }
    }
    return;
}


sub save_enemy_data {
    my ($self, $file_name) = @_;
    
    open (my $ENEMY_FH, '>', $file_name) or do {
        $self->logger->error("Failed to open output enemy file: $file_name :: $!");
        return;
    };

    my %enemies_to_save = $self->enemy_hash->%*;
    my @enemies_array;
    foreach my $enemy_id (keys %enemies_to_save) {
        # $self->logger->info("Saving enemy: " . Dumper \$enemies_to_save{$enemy_id});
        push(@enemies_array, $enemies_to_save{$enemy_id});        

    }
    my $enemy_json = encode_json(\@enemies_array);
    $self->logger->info("Enemies to save: " . Dumper \$enemy_json);
    print $ENEMY_FH $enemy_json;
    close($ENEMY_FH);

    return 1;
}

1;