package RpgServer::AuthorizationService;

use feature qw(say);
use Moo;

use MIME::Base64;
use Data::UUID;

has config => (
    is       => 'ro',
    required => 1
);

my $SERVER_KEY;
my %user_hash;
my %valid_tokens;
my $log = Mojo::Log->new;

sub BUILD {
    my ($self, $args) = @_;
    $SERVER_KEY = $self->config->{SERVER_KEY};
}

sub generate_token {
    my ($self, $id) = @_;

    my $ug = Data::UUID->new;
    my $token = $ug->create_from_name($SERVER_KEY, (localtime().$id));
    my $token_str = $ug->to_string($token);

    $log->info("Generated new token: $token_str for id: $id");
    $valid_tokens{$id} = $token_str;    

    return $token_str;
}


sub validate_token_auth {
    my ($self, $authorization_header, $id_param) = @_;

     #return 1;

    if (!length $authorization_header || $authorization_header !~ m/Basic /) {
        $log->info("Authorization header missing or invalid in get tokens call.");
        return 0;
    }

    my $basic_auth_val = (split(" ", $authorization_header))[1];  
    # my $basic_auth_val = $basic_auth_vals[1];

    my $decoded_auth = MIME::Base64::decode($basic_auth_val);
    my @creds = split(':', $decoded_auth);
    my $username = $creds[0];
    my $password = $creds[1];

    $log->info("Basic auth header=$authorization_header split=$basic_auth_val decoded=$decoded_auth user=$username password=$password");
    
    return ($password eq $SERVER_KEY && $username eq $id_param);
        
}


sub validate_auth {
    my ($self, $authorization_header, $id_param) = @_;

     #return 1;

    if ($authorization_header !~ m/Basic /) {
        return 0;
    }


    my $basic_auth_val = (split(" ", $authorization_header))[1];  
    # my $basic_auth_val = $basic_auth_vals[1];

    my $decoded_auth = MIME::Base64::decode($basic_auth_val);
    my @creds = split(':', $decoded_auth);
    my $username = $creds[0];
    my $password = $creds[1];

    $log->info("Basic auth header=$authorization_header split=$basic_auth_val decoded=$decoded_auth user=$username password=$password");

    # id param is only passed if required to match the id in the basic auth header.
    if (defined $id_param) {
        if ($id_param ne $username) {
            return 0;
        }
    }

    if ($valid_tokens{$username} ne $password) {
        $log->warn("Invalid token: $password passed for id: $username. Cannot add new user.");
        foreach my $key (keys %valid_tokens) {
            $log->info("Valid tokens: key: $key value: $valid_tokens{$key}");
        }
        return 0;
    }

    return 1;
}

1;
