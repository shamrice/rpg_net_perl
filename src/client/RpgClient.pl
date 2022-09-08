#!/usr/bin/perl
package RpgClient;

use strict;
use warnings;

BEGIN {
    push @INC, "./";
}

use Log::Log4perl qw(:easy);
use Getopt::Long;
use Pod::Usage;

use RpgClient::IO::UserInput;
use RpgClient::IO::Screen;
use RpgClient::IO::Network;
use RpgClient::User;
use RpgClient::Map;
use RpgClient::Engine;
use RpgClient::Configuration;

Log::Log4perl->init('./RpgClient/conf/log4perl.conf');


sub main { 
    
    my $player_name;
    my $player_token;
    my $help;
    my $man_page;
    my $config_file = "./RpgClient/conf/client.conf";
    

    GetOptions(
        "name=s" => \$player_name,
        "token=s" => \$player_token,
        "config=s" => \$config_file,
        "help|?" => \$help,        
        "man" => \$man_page,        
    ) or pod2usage(2);

    pod2usage(0) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man_page;

    my $logger = Log::Log4perl->get_logger("RpgClient");
    $logger->info("RpgClient is starting up...");

    my $config = RpgClient::Configuration::get_config($config_file);


    if (not defined $player_name) {
        print "Please enter a player name: ";
        $player_name = <>;
        chomp($player_name);
    }

    if (not defined $player_token) {
        print "Please enter a player token: ";
        $player_token = <>;
        chomp($player_token);
    }
    

    my $user = RpgClient::User->new(name => $player_name, user_char => $player_token);
    my %user_list = ($user->id => $user);

    my $net = RpgClient::IO::Network->new(user => $user, config => $config->{network});    

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

__END__
 
=head1 NAME
 
RpgClient - Client application for RpgServer
 
=head1 SYNOPSIS
 
RpgClient [options] 
 
 Options:
   --help           display help and exit
   --name           set player name
   --token          set player display token
   --config         specify config file to use (Default ./RpgClient/conf/client.conf)
   --man            displays full manual page
 
=head1 OPTIONS
 
=over 8
 
=item B<--help>
 
Print this help message and exit.
 
=item B<--name>
 
Set player's name
 
=item B<--token>
 
Set player's display token. This is the character used to represent the player on the map.
 
=item B<--config>

Specify configuration file to use in the application. If none is specified, it will use the default "./RpgClient/conf/client.conf".

=item B<--man>

Opens up perldoc manual page for running and using the RpgClient application.

=back
 
=head1 DESCRIPTION
 
B<This program> connects to the configured RpgServer and runs the game.
 
=cut

