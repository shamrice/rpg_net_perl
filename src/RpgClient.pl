#!/usr/bin/perl
package RpgClient;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use RpgClient::IO::UserInput;
use RpgClient::IO::Screen;
use RpgClient::IO::Network;
use RpgClient::User;
use RpgClient::Map;
use RpgClient::Engine;

Log::Log4perl->init('./RpgClient/conf/log4perl.conf');

sub main {

    my $logger = Log::Log4perl->get_logger("RpgClient");
    $logger->info("RpgClient is starting up...");

    print "Please enter a player name: ";
    my $player_name = <>;
    chomp($player_name);

    print "Please enter a player token: ";
    my $player_token = <>;
    chomp($player_token);


    my $user = RpgClient::User->new(name => $player_name, user_char => $player_token);
    my %user_list = ($user->id => $user);

    my $net = RpgClient::IO::Network->new(user => $user);    

    my $scr = RpgClient::IO::Screen->new(use_term_colors => 1);
    my $inp = RpgClient::IO::UserInput->new(screen => $scr->{screen});
    my $map = RpgClient::Map->new(screen => $scr);

    my $engine = RpgClient::Engine->new(
        user => $user, 
        user_list => \%user_list, 
        net => $net, 
        scr => $scr, 
        inp => $inp, 
        map => $map
    );

    $engine->init or die "Unable to initialize engine. $!\n";
    $engine->run;

    return 0;
}

exit(main());

=pod
print "Please enter a player name: ";
my $player_name = <>;
chomp($player_name);

print "Please enter a player token: ";
my $player_token = <>;
chomp($player_token);


my $user = RpgClient::User->new(name => $player_name, user_char => $player_token);
my %user_list = ($user->id => $user);

my $net = RpgClient::IO::Network->new(user => $user);
$net->authenticate or die "Error getting tokens from server: $!";
$net->add_user or die "Failed to add new user to server: $!";

my $scr = RpgClient::IO::Screen->new;
my $inp = RpgClient::IO::UserInput->new(screen => $scr->{screen});
my $map = RpgClient::Map->new(screen => $scr);

$scr->refresh;

my $is_running = 1;
my $polling_time = time();
say "polling time = $polling_time";

my $exit_message = "Exiting...";

#debug loading and printing map data.
my $map_data_raw = $net->get_map(0, 0, 0);

$map->set_map_data($map_data_raw);
$map->draw_map;


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
                $scr->draw(81, $y, $current_users_str);
                $y++;
                $scr->draw(81, $y, "name=".$user_list{$user}->name);
                $y++;
                $scr->draw(81, $y, "user_char=".$user_list{$user}->user_char);
                $y++;
                $scr->draw(81, $y, "x=".$user_list{$user}->x);
                $y++;
                $scr->draw(81, $y, "y=".$user_list{$user}->y); 
                $y++;
                $scr->draw(81, $y, "old_x=".$user_list{$user}->old_x);
                $y++;
                $scr->draw(81, $y, "old_y=".$user_list{$user}->old_y);
                $y++;
                $scr->draw(81, $y, "needs_redraw=".$user_list{$user}->needs_redraw);
                $y++;                                          
            }     
        }
    }    

    if ($moved) {        
        if ($net->update_user($user->x, $user->y)) {                 
            
            # TODO : include all draws together
            $scr->draw($user->x, $user->y, $user->user_char);

            $scr->draw(
                $user->old_x, 
                $user->old_y, 
                $map->get_tile($user->old_x, $user->old_y)                
            );
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
 

$scr->draw(40, 22, $exit_message);
$inp->blocking_getch;

$scr->refresh;

$net->remove_user;

exit(0);


sub update_and_draw_players {
    die "ERROR: User does not exist in current list of users" if !$net->get_players(\%user_list);  

    foreach my $user_to_draw (keys %user_list) {    

        #draw a mask over inactive users and remove them from the hash.
        
        if (!$user_list{$user_to_draw}->is_active) {   
                        
            $scr->draw(
                $user_list{$user_to_draw}->x, 
                $user_list{$user_to_draw}->y,                 
                $map->get_tile($user_list{$user_to_draw}->x, $user_list{$user_to_draw}->y)
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
                $map->get_tile($user_list{$user_to_draw}->old_x, $user_list{$user_to_draw}->old_y)
            );
        }
    } 
}
=cut;

