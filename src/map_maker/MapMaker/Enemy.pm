package MapMaker::Enemy;

use Moo;
use Data::UUID;
use Data::Dumper;

has enemies => (
    is => 'rwp'
);

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("MapMaker") }
);

sub add_enemy {
    my ($self, %enemy_info) = @_;

    $self->logger->info("New enemy: " . Dumper \%enemy_info);

    #todo : validate enemy info hash is valid.

    my $ug = Data::UUID->new;
    my $user_id_raw = $ug->create_from_name($ug->create, (localtime().$ug->create()));
    my $enemy_id = "ENEMY-" . $ug->to_string($user_id_raw);

    $enemy_info{id} = $enemy_id;

    

    $self->{enemies}->{$enemy_info{id}} = {%enemy_info};

    $self->logger->info("Current enemy array: " . Dumper \$self->enemies);
}

1;