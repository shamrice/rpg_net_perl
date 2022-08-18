#!/usr/bin/perl

package RpgClient::Engine;

use feature qw(say switch);
use Time::HiRes qw(time);

use Moo;

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


sub init {
    my $self = shift;

    $self->net->authenticate or die "Error getting tokens from server: $!";
    $self->net->add_user or die "Failed to add new user to server: $!";

    return 1;
}

sub run {
    my $self = shift;


    $self->scr->refresh;

    my $is_running = 1;
    my $polling_time = time();
    say "polling time = $polling_time";

    my $exit_message = "Exiting...";

    #debug loading and printing map data.
    my $map_data_raw = $self->net->get_map(0, 0, 0);

    $self->map->set_map_data($map_data_raw);
    $self->map->draw_map;


    $self->update_and_draw_players;

    while ($is_running && $self->user->is_alive) {

        my $char_input = $self->inp->getch;
        my $moved = 0;

        if ($char_input =~ m/(?:w|a|s|d)/) {              
            $moved = 1;      
        }

        given ($char_input) {
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
        }    

        if ($moved) {   
            $self->map->handle_map_interaction($self->user);

            if ($self->net->update_user($self->user->x, $self->user->y)) {                 
            
                # TODO : include all draws together
                $self->scr->draw($self->user->x, $self->user->y, $self->user->user_char);

                $self->scr->draw(
                    $self->user->old_x, 
                    $self->user->old_y, 
                    $self->map->get_tile($self->user->old_x, $self->user->old_y)                
                );
            } else {
                $is_running = 0;
                $exit_message = "Failed send player update to server. Forced quit.";
            }
        }

        if ((time() - $polling_time) > 0.05) {                
            $polling_time = time();                
            $self->update_and_draw_players;
        }

        $self->draw_player_stats;

        if (!$self->user->is_alive) {
            $self->handle_death;
        }

    }
 

    $self->scr->draw(40, 22, $exit_message);
    $self->inp->blocking_getch;

    $self->scr->refresh;

    $self->net->remove_user;

}

sub update_and_draw_players {
    my $self = shift;

    $self->net->get_players($self->user_list) or die "ERROR: User does not exist in current list of users";

    my %user_list = %{$self->user_list};

    foreach my $user_to_draw (keys %user_list) {    

        #draw a mask over inactive users and remove them from the hash.
        
        if (!$user_list{$user_to_draw}->is_active) {   
                        
            $self->scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y,                 
                $self->map->get_tile($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y)
            );

            delete $user_list{$user_to_draw};

        } elsif ($user_list{$user_to_draw}->needs_redraw) {
            
            $self->scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y, 
                $user_list{$user_to_draw}->user_char
            );                    

            $self->scr->draw(
                $user_list{$user_to_draw}->old_x, 
                $user_list{$user_to_draw}->old_y, 
                $self->map->get_tile($user_list{$user_to_draw}->old_x, $user_list{$user_to_draw}->old_y)
            );
        }
    } 
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

1;