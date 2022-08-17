#!/usr/bin/perl
package RpgClient;

use strict;
use warnings;

use Time::HiRes qw(time);

use feature qw(say switch);

use RpgClient::IO::UserInput;
use RpgClient::IO::Screen;
use RpgClient::IO::Network;
use RpgClient::User;


print "Please enter a player name: ";
my $player_name = "#"; #<>;
print "Please enter a player token: ";
my $player_token = "#"; #<>;


my $user = RpgClient::User->new(name => $player_name, user_char => $player_token);
my %user_list = ($user->id => $user);

my $net = RpgClient::IO::Network->new(user => $user);
$net->authenticate or die "Error getting tokens from server: $!";
$net->add_user or die "Failed to add new user to server: $!";


# exit 1;

my $scr = RpgClient::IO::Screen->new;
my $inp = RpgClient::IO::UserInput->new(screen => $scr->{screen});

$scr->refresh;

my $is_running = 1;
my $polling_time = time();
say "polling time = $polling_time";
# exit 1;

my $exit_message = "Exiting...";

update_and_draw_players();

while ($is_running) {

    my $char_input = $inp->getch;
    my $moved = 0;

    if ($char_input =~ m/(?:w|a|s|d)/) {
        my @current_position = $user->get_position;    
        $scr->draw($current_position[0], $current_position[1], ' ');       
        $moved = 1;      
    }

    given ($char_input) {
        when ('q') {
            $is_running = 0;
        }
        when ('w') {
            $user->move(0, -1);
        }
        when ('s') {
            $user->move(0, 1);
        }
        when ('a') {
            $user->move(-1, 0);
        }
        when ('d') {
            $user->move(1, 0);
        }
        when ('u') {
            my $y = 1;
            foreach my $user (keys %user_list) {
                my $current_users_str = "";
                $current_users_str = "id=".$user_list{$user}->id;
                $scr->draw(80, $y, $current_users_str);
                $y++;
                $scr->draw(80, $y, "name=".$user_list{$user}->name);
                $y++;
                $scr->draw(80, $y, "user_char=".$user_list{$user}->user_char);
                $y++;
                $scr->draw(80, $y, "x=".$user_list{$user}->x);
                $y++;
                $scr->draw(80, $y, "y=".$user_list{$user}->y); 
                $y++;
                $scr->draw(80, $y, "old_x=".$user_list{$user}->old_x);
                $y++;
                $scr->draw(80, $y, "old_y=".$user_list{$user}->old_y);
                $y++;
                $scr->draw(80, $y, "needs_redraw=".$user_list{$user}->needs_redraw);
                $y++;                                          
            }

            
        }
    }    

    if ($moved) {        
        if ($net->update_user($user->x, $user->y)) {     
            $scr->draw($user->x, $user->y, $user->user_char);
        } else {
            $is_running = 0;
            $exit_message = "Failed send player update to server. Forced quit.";
        }
    }

    if ((time() - $polling_time) > 0.05) {                
        $polling_time = time();                
        update_and_draw_players();
    }

}
 

$scr->draw(40, 20, $exit_message);
$inp->blocking_getch;

$scr->refresh;

$net->remove_user;

exit(0);


sub update_and_draw_players {
    die "ERROR: User does not exist in current list of users" if !$net->get_players(\%user_list);  

    foreach my $user_to_draw (keys %user_list) {    

        #draw a mask over inactive users and remove them from the hash.
        #TODO : should draw ground char instead of just space.
        if (!$user_list{$user_to_draw}->is_active) {   
            
            $scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y, 
                ' '
            );

            delete $user_list{$user_to_draw};

        } elsif ($user_list{$user_to_draw}->needs_redraw) {
            
            $scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y, 
                $user_list{$user_to_draw}->user_char
            );

            $scr->draw(
                $user_list{$user_to_draw}->old_x, 
                $user_list{$user_to_draw}->old_y, 
                ' '
            );
        }
    } 
}

