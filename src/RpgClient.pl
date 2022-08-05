#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw(time);

use feature qw(say switch);

use RpgClient::IO::UserInput;
use RpgClient::IO::Screen;
use RpgClient::IO::Network;
use RpgClient::User;


print "Please enter a player name: ";
my $player_name = <>;
print "Please enter a player token: ";
my $player_token = <>;


my $user = RpgClient::User->new($player_name, $player_token);
my %user_list = ($user->get_id => $user);

my $net = RpgClient::IO::Network->new($user);
$net->authenticate or die "Error getting tokens from server: $!";
$net->add_user or die "Failed to add new user to server: $!";


# exit 1;

my $scr = RpgClient::IO::Screen->new;
my $inp = RpgClient::IO::UserInput->new($scr->{screen});

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
    }    

    if ($moved) {        
        if ($net->update_user($user->{x}, $user->{y})) {     
            $scr->draw($user->{x}, $user->{y}, $user->{user_char});
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


say "\n\n\n\n$exit_message\n";
$inp->blocking_getch;

$scr->refresh;

exit(0);


sub update_and_draw_players {
    die "ERROR: User does not exist in current list of users" if !$net->get_players(\%user_list);  

    foreach my $user_to_draw (keys %user_list) {    

        if ($user_list{$user_to_draw}->{needs_redraw}) {
            
            $scr->draw(
                $user_list{$user_to_draw}->{x}, 
                $user_list{$user_to_draw}->{y}, 
                $user_list{$user_to_draw}->{user_char}
            );

            $scr->draw(
                $user_list{$user_to_draw}->{old_x}, 
                $user_list{$user_to_draw}->{old_y}, 
                ' '
            );
        }
    } 
}

