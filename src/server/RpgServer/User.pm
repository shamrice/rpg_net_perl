package RpgServer::User;

use Data::UUID;
use Moo;

has id => (
    is => 'rwp',
    required => 1
);

has name => (
    is => 'rwp',
    required => 1
);

has user_char => (
    is => 'rwp',
    required => 1
);

has x => (
    is => 'rwp',
    required => 1
);

has y => (
    is => 'rwp',
    required => 1
);

has world_id => (
    is => 'rwp',
    required => 1
);

has map_x => (
    is => 'rwp',
    required => 1
);

has map_y => (
    is => 'rwp',
    required => 1
);

has last_activity => (
    is => 'rwp'
    # default => time() # this doesn't work. It sets it to the time the server started.
);

sub BUILD {
    my ($self, $args) = @_;
    $self->_set_last_activity(time());
}


sub update {
    my ($self, $user_attributes) = @_;    

    if (exists $user_attributes->{world_id}) {
        $self->_set_world_id($user_attributes->{world_id});
    }

    if (exists $user_attributes->{map_x}) {        
        $self->_set_map_x($user_attributes->{map_x});        
    }
    if (exists $user_attributes->{map_y}) {        
        $self->_set_map_y($user_attributes->{map_y});
    }
    if (exists $user_attributes->{x}) {        
        $self->_set_x($user_attributes->{x});        
    }
    if (exists $user_attributes->{y}) {        
        $self->_set_y($user_attributes->{y});
    }
    if (exists $user_attributes->{name}) {
        $self->_set_name($user_attributes->{name});
    }
    if (exists $user_attributes->{user_char}) {
        $self->_set_user_char($user_attributes->{user_char});
    }   

    $self->_set_last_activity(time()); 
}


sub to_string {
    my $self = shift;
    my $id = $self->id;
    my $name = $self->name;
    my $user_char = $self->user_char;
    my $world_id = $self->world_id;
    my $map_x = $self->map_x;
    my $map_y = $self->map_y;
    my $x = $self->x;
    my $y = $self->y;
    my $last_activity = $self->last_activity;

    return "User id: $id :: name: $name :: user_char: $user_char :: world_id: $world_id :: map_x: $map_x :: map_y: $map_y x: $x :: y: $y :: last_activity: $last_activity";
}

1;