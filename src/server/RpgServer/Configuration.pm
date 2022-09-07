package RpgServer::Configuration;
use strict;
use warnings FATAL => 'all';
use feature qw(say);
use Data::Dumper;
use Config::Tiny;

sub get_config {
    my ($config_file, $dump_configs_to_stdout) = @_;

    if (not defined $config_file) {
        die "Cannot start server without a configuration file specified.";
    }
    my $config = Config::Tiny->read($config_file, "utf8");
    if (not defined $config) {
        die "Error loading configuration file: $config";
    }
    if ($dump_configs_to_stdout) {
        say "Loaded config: " . Dumper \$config;
    }
    return $config;
}


1;