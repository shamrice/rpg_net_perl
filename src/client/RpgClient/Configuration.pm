package RpgClient::Configuration;

use strict;
use warnings FATAL => 'all';
use feature qw(say);
use Data::Dumper;
use Config::Tiny;


sub get_config {
    my $config_file = shift;

    my $log = Log::Log4perl->get_logger("RpgClient");    

    if (not defined $config_file) {
        die "Cannot start client without a configuration file specified. :: $!\n";
    }

    $log->info("Using configuration file: $config_file");

    my $config = Config::Tiny->read($config_file, "utf8");
    if (not defined $config) {
        die "Error loading configuration file: $config_file :: $!\n";
    }
    
    $log->debug("Loaded config: " . Dumper \$config);
    
    return $config;
}

1;
