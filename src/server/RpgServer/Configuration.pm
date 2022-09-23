package RpgServer::Configuration;
use strict;
use warnings FATAL => 'all';
use feature qw(say);
use Data::Dumper;
use Config::Tiny;
use FindBin;

my $log = Mojo::Log->new;

sub get_config {
    my ($config_file, $dump_configs_to_stdout) = @_;

    if (not defined $config_file) {
        die "Cannot start server without a configuration file specified.";
    }
    my $config = Config::Tiny->read($config_file, "utf8");
    if (not defined $config) {
        die "Error loading configuration file: $config";
    }

    __convert_relative_to_absolute_dir_path($config) if $config->{data}{CONVERT_RELATIVE_TO_ABSOLUTE_DIR_PATH};

    if ($dump_configs_to_stdout) {
        $log->info("Loaded config: " . Dumper \$config);
    }
    return $config;
}


sub __convert_relative_to_absolute_dir_path {
    my ($config) = shift;

    my @dir_keys = grep(/^.*_DIRECTORY$/, keys %{$config->{data}});    
    
    foreach my $dir_key (@dir_keys) {
        my $relative_path = $config->{data}{$dir_key};
        $relative_path =~ s/^\.//;

        if ($relative_path !~ m/^\//) {
            $relative_path = "/" . $relative_path;
        }

        $config->{data}{$dir_key} = $FindBin::Bin . $relative_path;
    }
}

1;