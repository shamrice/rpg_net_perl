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
    my ($self, $map_x, $map_y, $x, $y, $name, $user_char) = @_;

    if (defined $map_x) {        
        $self->_set_map_x($map_x);        
    }
    if (defined $map_y) {        
        $self->_set_map_y($map_y);
    }
    if (defined $x) {        
        $self->_set_x($x);        
    }
    if (defined $y) {        
        $self->_set_y($y);
    }
    if (defined $name) {
        $self->_set_name($name);
    }
    if (defined $user_char) {
        $self->_set_user_char($user_char);
    }   

    $self->_set_last_activity(time()); 
}


sub to_string {
    my $self = shift;
    my $id = $self->id;
    my $name = $self->name;
    my $user_char = $self->user_char;
    my $map_x = $self->map_x;
    my $map_y = $self->map_y;
    my $x = $self->x;
    my $y = $self->y;
    my $last_activity = $self->last_activity;

    return "User id: $id :: name: $name :: user_char: $user_char :: map_x: $map_x :: map_y: $map_y x: $x :: y: $y :: last_activity: $last_activity";
}

1;