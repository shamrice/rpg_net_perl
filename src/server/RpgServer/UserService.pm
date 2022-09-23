package RpgServer::UserService;

use strict;
use warnings;
use Moo;

use RpgServer::User;

my $log = Mojo::Log->new;
my %user_hash;

has config => (
    is       => 'ro',
    required => 1
);

=pod

# TODO : Figure out getting a polling thread running that removes inactive users instead of relying on get users call checking.

sub activity_timeout_checker {
    threads->create(sub {
        my $thread_id = threads->self->tid;
        $log->info("Starting activity timeout thread id: $thread_id");

        while (1) {
            # $log->info("Checking for any inactive users.");
            lock(%user_hash);            
            foreach my $user_id (keys %user_hash) {
                say "Checking user $user_id";
                my $current_user = $user_hash{$user_id};
                if (time() - $current_user->{last_activity} > PLAYER_TIMEOUT_SECONDS) {
                    $log->info("User: $user_id has timed out and will be removed from the server.");
                    delete $user_hash{$user_id};                
                }
            }
            sleep(60);
        }

        threads->detach(); # end thread
    });
} 
=cut


sub add_user {
    my ($self, $id, $name, $user_char, $world_id, $map_x, $map_y, $x, $y) = @_;

    # TODO : validate that the values sent in are sane / valid.
 
    my $new_user = RpgServer::User->new(
        id => $id, 
        name => $name, 
        user_char => $user_char, 
        world_id => $world_id,
        map_x => $map_x,
        map_y => $map_y,
        x => $x, 
        y => $y
    );    

    my $new_id = $new_user->id;
    $log->info("New id = $new_id");

    if (exists $user_hash{$new_id}) {
        my $user_str = $user_hash{$new_id}->to_string();
        $log->warn("Tried to add already existing user:  $user_str");
        return 0;
    }     

    $user_hash{$new_user->id} = $new_user;

    my $user_str = $user_hash{$new_id}->to_string();
    $log->info("Added user :: $user_str");   

    return 1;
}


sub update_user {
    my ($self, $id, $name, $user_char, $world_id, $map_x, $map_y, $x, $y) = @_;
    
    # TODO : validate that the values sent in are sane / valid.

    if (not exists $user_hash{$id}) {    
        $log->warn("Tried to update a user that doesn't exist: $id");
        return 0;        
    }
 
    $log->info("Updating user id: $id :: world_id: $world_id :: map_x: $map_x : map_y: $map_y : x: $x : y: $y name: $name : user_char: $user_char ");
       
    $user_hash{$id}->update($world_id, $map_x, $map_y, $x, $y, $name, $user_char);
    return 1;
}


sub get_users {
    my $self = shift;

    my $num_current_users = keys %user_hash;
    $log->info("Current number of found users: $num_current_users");

    my $user_list = [ ];
    foreach my $user_id (keys %user_hash) {

        my $found_user = $user_hash{$user_id};
        my $found_user_id = $found_user->id;
        $log->info("Found user: ".$found_user->to_string);
                
        if (time() - $found_user->last_activity > $self->config->{PLAYER_TIMEOUT_SECONDS}) {
            $log->info("User: $found_user_id has timed out and will be removed from the server.");
            delete $user_hash{$found_user_id};
            next;
        }
       
        push @$user_list, { 
            id => $found_user->id, 
            name => $found_user->name,
            user_char => $found_user->user_char,
            world_id => $found_user->world_id,
            map_x => $found_user->map_x,
            map_y => $found_user->map_y,
            x => $found_user->x,
            y => $found_user->y
        }; 
    }
    return $user_list;
}


sub get_users_at {
    my ($self, $world_id, $map_x, $map_y) = @_;

    
    my $user_list = [ ];
    foreach my $user_id (keys %user_hash) {

        my $found_user = $user_hash{$user_id};

        if ($found_user->world_id == $world_id && $found_user->map_x == $map_x && $found_user->map_y == $map_y) {

            my $found_user_id = $found_user->id;
            $log->info("Found user: ".$found_user->to_string);
               
       
            push @$user_list, { 
                id => $found_user->id, 
                name => $found_user->name,
                user_char => $found_user->user_char,
                world_id => $found_user->world_id,
                map_x => $found_user->map_x,
                map_y => $found_user->map_y,
                x => $found_user->x,
                y => $found_user->y
            }; 
        }
    }

    $log->info("At: $world_id, $map_x, $map_y :: Current number of found users: ".(scalar @$user_list));
    return $user_list;
}

sub get_user {
    my ($self, $id) = @_;

    if (not exists $user_hash{$id}) {
        return;
    }
    
    my $found_user = $user_hash{$id};

    my $user = {
        id => $found_user->id,
        name => $found_user->name,
        user_char => $found_user->user_char,
        map_x => $found_user->map_x,
        map_y => $found_user->map_y,
        x => $found_user->x,
        y => $found_user->y
    };

    return $user;
}


sub remove_user {
    my ($self, $id) = @_;

    if (not exists $user_hash{$id}) {
        return 0;
    }

    $log->info("Removing user: $id from the game.");
    delete $user_hash{$id};
    return 1;
}

1;
