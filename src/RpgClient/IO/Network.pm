package RpgClient::IO::Network;

use Mojo::UserAgent;
use Data::UUID;

use feature qw(say);
use strict;
use warnings;

use constant SERVER_KEY => "B2F55FE4-B9FD-421E-8764-51CBC323E36C";
use constant SERVER_HOST => "http://localhost:3000";
use constant TOKEN_ENDPOINT => "/rest/token/";
use constant ADD_USER_ENDPOINT => "/rest/user/add/";
use constant UPDATE_USER_ENDPOINT => "/rest/user/";
use constant GET_USERS_ENDPOINT => "/rest/users";

sub new {
    my ($class, $user) = @_;

    my $ua = Mojo::UserAgent->new;

    my $self = { 
        user => $user,        
        user_agent => $ua        
    };

    bless $self, $class;
}

sub authenticate {
    my $self = shift;

    my $username = $self->{user}->get_id;    

    my $url = Mojo::URL->new(SERVER_HOST.TOKEN_ENDPOINT.$username)->userinfo("$username:".SERVER_KEY);
    my $token_response =  $self->{user_agent}->get($url)->result->json;

    my $token_status = $token_response->{status};
    my $token_code = $token_response->{code};
    my $token_value = $token_response->{token};

    say "Json token response: $token_status : $token_code : $token_value";

    if ($token_code != 200) {
        say "Error getting tokens: $token_status : $token_code : $token_value";
        return 0;
    }

    $self->{token} = $token_value;
    say "Successfully authenticated $username with server.";
    return 1;
}



sub add_user {
    my $self = shift;

    my $username = $self->{user}->get_id;
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.ADD_USER_ENDPOINT.$username)->userinfo("$username:$password");


    my $req_body = {
        id => $self->{user}->get_id,
        name => $self->{user}->get_name,
        user_char => $self->{user}->get_user_char,
        x => $self->{user}->get_x,
        y => $self->{user}->get_y
    };

    my $response =  $self->{user_agent}->post($url => json => $req_body)->result->json;

    my $status = $response->{status};
    my $code = $response->{code};    

    say "Json add user response: $status : $code ";

    if ($code != 200) {
        say "Error adding user: $username : response: $status : $code";
        return 0;
    }
    
    say "Successfully add player $username on the server.";
    return 1;

}


sub update_user {
    my ($self, $x, $y, $name, $user_char) = @_;

    my $username = $self->{user}->get_id;
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.UPDATE_USER_ENDPOINT.$username)->userinfo("$username:$password");

    my $req_body = {
        id => $self->{user}->get_id
    };

    if (defined $x) {
        $req_body->{x} = $x;
    }
    if (defined $x) {
        $req_body->{y} = $y;
    }
    if (defined $x) {
        $req_body->{name} = $name;
    }
    if (defined $x) {
        $req_body->{user_char} = $user_char;
    }

    my $response =  $self->{user_agent}->put($url => json => $req_body)->result->json;

    my $status = $response->{status};
    my $code = $response->{code};    

    # say "Json update user response: $status : $code ";
    if ($code != 200) {
        say "Error updating user: $username : response: $status : $code :: $!";
        return 0;
    }
    
    # say "Successfully updated player $username on the server.";
    return 1;
}


sub get_players {
    my ($self, $current_player_list) = @_;

    my $username = $self->{user}->get_id;    
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.GET_USERS_ENDPOINT)->userinfo("$username:$password");
    my $response =  $self->{user_agent}->get($url)->result->json;

    my $status = $response->{status};
    my $code = $response->{code};   
    my $users = $response->{users}; 

    #my $numKeys = keys $current_player_list;
    #say "Size: $numKeys";

    # say "Json get users response: $status : $code : $users ";

    if ($code != 200) {
        say "Error getting users: $status : $code ";
        return 0;
    }
    
    my $current_user_found = 0;

    foreach my $user (@$users) {        
        my $user_id = $user->{id};

        if ($user_id eq $self->{user}->{id}) {
            $current_user_found = 1;            
        }

        my $old_x = 0;
        my $old_y = 0;
        my $force_redraw = 0;

        if (exists $$current_player_list{$user_id}) {
            $old_x = $$current_player_list{$user_id}->{x};
            $old_y = $$current_player_list{$user_id}->{y};                        
        } else {
            $force_redraw = 1;
        }
        
        $$current_player_list{$user_id} = {
            id => $user_id,
            name => $user->{name},
            user_char => $user->{user_char},
            x => $user->{x},
            y => $user->{y},
            old_x => $old_x,
            old_y => $old_y
        };
        
        $$current_player_list{$user_id}->{needs_redraw} = (   
            $force_redraw ||          
            ($$current_player_list{$user_id}->{old_x} != $$current_player_list{$user_id}->{x} || 
            $$current_player_list{$user_id}->{old_y} != $$current_player_list{$user_id}->{y})
        );
        
    }

    # returns failure if current user isn't found in the server user list.
    return $current_user_found; 
}

1;