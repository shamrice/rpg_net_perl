package RpgClient::Engine;

use Data::Dumper;

use feature qw(say switch); # TODO : Stop using given/when
use Time::HiRes qw(time);

use Moo;

no warnings qw( experimental::smartmatch ); # TODO : remove when given/when is removed.


has user => (
    is => 'ro',
    required => 1
);

has net => (
    is => 'ro',
    required => 1
);

has scr => (
    is => 'ro',
    required => 1
);

has inp => (
    is => 'ro',
    required => 1
);

has map => (
    is => 'ro',
    required => 1
);


has user_list => (
    is => 'rw',
);

has logger => (
    is      => 'ro',
    default => sub { Log::Log4perl->get_logger("RpgClient") }
);


sub init {
    my $self = shift;

    $self->net->authenticate or die "Error getting tokens from server: $!";
    $self->net->add_user or die "Failed to add new user to server: $!";

    return 1;
}

sub run {
    my $self = shift;

    $self->logger->info("Engine starting.");
    
    $self->scr->refresh;

    my $is_running = 1;
    my $polling_time = time();
    say "polling time = $polling_time";

    my $exit_message = "Exiting...";

    $self->load_current_map;


    $self->update_and_draw_players;

    while ($is_running && $self->user->is_alive) {

        my $char_input = $self->inp->getch;
        my $moved = 0;

        if ($char_input =~ m/(?:w|a|s|d)/) {              
            $moved = 1;      
        }

        for ($char_input) {
            when ('q') {
                $is_running = 0;
            }
            when ('w') {
                $self->user->move(0, -1);
            }
            when ('s') {
                $self->user->move(0, 1);
            }
            when ('a') {
                $self->user->move(-1, 0);
            }
            when ('d') {
                $self->user->move(1, 0);
            }
            when ('u') {
                $self->draw_debug_user_list;
            }
            when ('t') {
                $self->handle_chat_input;
            }
            when ('y') {
                $self->get_chat_log;
            }
        }    

        if ($moved) {   
            
            if (!$self->map->handle_map_interaction($self->user) && !$self->check_player_collision) {                               

                if ($self->user->needs_map_load) {
                    $self->logger->info("needs_map_load == true : Loading new map: " . $self->user->world_id . "," . $self->user->map_x . "," . $self->user->map_y);
                    $self->load_current_map;
                } 

                if ($self->net->update_user($self->user->world_id, $self->user->map_x, $self->user->map_y, $self->user->x, $self->user->y)) {
                    

                    # TODO : include all draws together
                    # TODO : Maybe get the tile as a whole as a single hash with id, attr, fg and bg colors.
                    $self->scr->draw(
                        $self->user->x, 
                        $self->user->y, 
                        $self->user->user_char,
                        9,
                        $self->map->get_background_color($self->user->x, $self->user->y)
                    );

                    $self->scr->draw(
                        $self->user->old_x, 
                        $self->user->old_y, 
                        $self->map->get_tile($self->user->old_x, $self->user->old_y),
                        $self->map->get_foreground_color($self->user->old_x, $self->user->old_y),                      
                        $self->map->get_background_color($self->user->old_x, $self->user->old_y)
                    );
                    

                } else {
                    $is_running = 0;
                    $exit_message = "Failed send player update to server. Forced quit.";
                }
            }
        }

        if ((time() - $polling_time) > 0.25 ) { # 0.05) {                
            $polling_time = time();                
            $self->update_and_draw_players;
        }

        $self->draw_player_stats;

        if (!$self->user->is_alive) {
            $self->handle_death;
        }

    }

    $self->logger->info("Engine is shutting down...");

    $self->scr->draw(40, 22, $exit_message);
    $self->inp->blocking_getch;
    $self->scr->echo(1); #reset cursor back to original style.
    $self->scr->refresh;

    $self->net->remove_user;

}

sub update_and_draw_players {
    my $self = shift;

    $self->net->get_players($self->user->world_id, $self->user->map_x, $self->user->map_y, $self->user_list); # or die "ERROR: User does not exist in current list of users";

    my %user_list = %{$self->user_list};
   

    foreach my $user_to_draw (keys %user_list) {    

        #draw a mask over inactive users and remove them from the hash.
        
        #TODO : get single tile hash that includes the tile, fg, and bg colors instead of making 3 calls to map.
        if (!$user_list{$user_to_draw}->is_active) {   
                        
            $self->scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y,                 
                $self->map->get_tile($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y),
                $self->map->get_foreground_color($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y),                      
                $self->map->get_background_color($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y)
            );

            $self->logger->info("User : " . $user_list{$user_to_draw}->id . " has left the game.");
            delete $user_list{$user_to_draw};

        } elsif ($user_list{$user_to_draw}->needs_redraw) {
            
            $self->scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y, 
                $user_list{$user_to_draw}->user_char,         
                15,                     
                $self->map->get_background_color($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y)                
            );                    

            $self->scr->draw(
                $user_list{$user_to_draw}->old_x, 
                $user_list{$user_to_draw}->old_y, 
                $self->map->get_tile($user_list{$user_to_draw}->old_x, $user_list{$user_to_draw}->old_y),
                $self->map->get_foreground_color($user_list{$user_to_draw}->old_x, $user_list{$user_to_draw}->old_y),                      
                $self->map->get_background_color($user_list{$user_to_draw}->old_x, $user_list{$user_to_draw}->old_y)
            );
        }
    } 
}


=pod 
    Check if player collides with something other than a map
    tile. If so, handles that collision or passes off to anther
    sub that can.
    Returns: true on blocking collision, otherwise false.
=cut

sub check_player_collision {
    my $self = shift;

    my %user_list = %{$self->user_list};

    foreach my $user_id (keys %user_list) {
        if ($user_id ne $self->user->id) {
            if ($self->user->x == $user_list{$user_id}->x && $self->user->y == $user_list{$user_id}->y) {      
                $self->user->undo_move;          
                return 1;
            }
        }
    }
    return 0;
}


sub draw_player_stats {
    my $self = shift;
    my %player_stats = $self->user->get_stats;

    my $stat_str = "HP: " . $player_stats{current_hp} . "/" . $player_stats{max_hp} . " STATUS: " . $player_stats{status};

    $self->scr->draw(1, 22, $stat_str);
}


sub draw_debug_user_list {
    my $self = shift;
    my $y = 1;
    foreach my $user (keys %{$self->user_list}) {
        my $current_users_str = "";
        $current_users_str = "id=".$self->user_list->{$user}->id;
        $self->scr->draw(81, $y, $current_users_str);
        $y++;
        $self->scr->draw(81, $y, "name=".$self->user_list->{$user}->name);
        $y++;
        $self->scr->draw(81, $y, "user_char=".$self->user_list->{$user}->user_char);
        $y++;
        $self->scr->draw(81, $y, "world_id=".$self->user_list->{user}->world_id);
        $y++;
        $self->scr->draw(81, $y, "map_x=".$self->user_list->{$user}->map_x);
        $y++;
        $self->scr->draw(81, $y, "map_y=".$self->user_list->{$user}->map_y); 
        $y++;
        $self->scr->draw(81, $y, "x=".$self->user_list->{$user}->x);
        $y++;
        $self->scr->draw(81, $y, "y=".$self->user_list->{$user}->y); 
        $y++;
        $self->scr->draw(81, $y, "old_x=".$self->user_list->{$user}->old_x);
        $y++;
        $self->scr->draw(81, $y, "old_y=".$self->user_list->{$user}->old_y);
        $y++;
        $self->scr->draw(81, $y, "needs_redraw=".$self->user_list->{$user}->needs_redraw);
        $y++;                                          
    } 
}

sub handle_death {
    my $self = shift;

    $self->scr->draw(10, 5, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    $self->scr->draw(10, 6, "!         Y O U     H A V E     D I E D           !");
    $self->scr->draw(10, 7, "!                                                 !");
    $self->scr->draw(10, 8, "!        Press any key to leave the game          !");
    $self->scr->draw(10, 9, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

    $self->inp->blocking_getch;
}


#TODO : maybe a better name as its loading and drawing?
sub load_current_map {
    my $self = shift;

    my $map_data_raw = $self->net->get_map($self->user->world_id, $self->user->map_x, $self->user->map_y);   
    
    $self->map->set_map_data($map_data_raw);
    $self->map->draw_map;  

    # Reset player list for the location and get fresh.
    $self->user_list({ });
    $self->update_and_draw_players;

    $self->scr->draw(
        $self->user->x, 
        $self->user->y, 
        $self->user->user_char,
        9,
        $self->map->get_background_color($self->user->x, $self->user->y)
    );  

    $self->logger->info("Map : " . $self->user->world_id . "," . $self->user->map_x . "," . $self->user->map_y . " has been loaded.");
    $self->user->needs_map_load(0);

}


sub handle_chat_input {
    my $self = shift;

    $self->scr->clear_line(23);
    $self->scr->draw(1, 23, "Say: ");    
    my $input = $self->inp->get_string_input;
    
    $self->scr->clear_line(23);
    if (length $input) {        
        $self->scr->draw(1, 23, "Said: $input length:". length $input);
        $self->net->add_chat_log($input);
    }
}

sub get_chat_log {
    my $self = shift;
    my $chat_log = $self->net->get_chat_log;
    $self->logger->info("Chat log = " . Dumper \$chat_log);

    for my $line (23..33) {
        $self->scr->clear_line($line);
    }

    my $y = 23;
    foreach my $log (@$chat_log) {
        $self->scr->draw(1, $y, $log);
        $y++;
    }
}

1;