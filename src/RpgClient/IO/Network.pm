package RpgClient::IO::Network;

use Mojo::UserAgent;
use Data::UUID;

use feature qw(say);
use Moo;
use Data::Dumper;

#TODO : these should be from a configuration

use constant SERVER_KEY => "B2F55FE4-B9FD-421E-8764-51CBC323E36C";
use constant SERVER_HOST => "http://localhost:3000";
use constant TOKEN_ENDPOINT => "/rest/token/";
use constant ADD_USER_ENDPOINT => "/rest/user/add/";
use constant UPDATE_USER_ENDPOINT => "/rest/user/";
use constant GET_USERS_ENDPOINT => "/rest/users";
use constant DELETE_USER_ENDPOINT => "/rest/user/";


has user => (
    is => "rwp",
    required => 1
);

has user_agent => (
    is => 'ro'
);

sub BUILD {
    my ($self, $args) = @_;
    my $ua = Mojo::UserAgent->new;
    $self->{user_agent} = $ua;
}


sub authenticate {
    my $self = shift;

    my $username = $self->{user}->id;    

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

    my $username = $self->{user}->id;
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.ADD_USER_ENDPOINT.$username)->userinfo("$username:$password");


    my $req_body = {
        id => $self->{user}->id,
        name => $self->{user}->name,
        user_char => $self->{user}->user_char,
        x => $self->{user}->x,
        y => $self->{user}->y
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

    my $username = $self->{user}->id;
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.UPDATE_USER_ENDPOINT.$username)->userinfo("$username:$password");

    my $req_body = {
        id => $self->{user}->id
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

    my $username = $self->{user}->id;    
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
            $old_x = $$current_player_list{$user_id}->x;
            $old_y = $$current_player_list{$user_id}->y;                        
        } else {
            $force_redraw = 1;
        }
    
        my $needs_redraw = $force_redraw ||          
            ($old_x != $user->{x} || $old_y != $user->{y});
        
        my $user_to_update = RpgClient::User->new(              
            name => $user->{name},
            user_char => $user->{user_char},
            x => $user->{x},
            y => $user->{y},
            old_x => $old_x,
            old_y => $old_y,
            needs_redraw => $needs_redraw   
        );

        $user_to_update->_set_id($user_id);
       

        $$current_player_list{$user_id} = $user_to_update;
    
    }

    # returns failure if current user isn't found in the server user list.
    return $current_user_found; 
}


sub remove_user {
    my $self = shift;

    my $username = $self->{user}->id;    
    my $password = $self->{token};

    my $url = Mojo::URL->new(SERVER_HOST.DELETE_USER_ENDPOINT.$username)->userinfo("$username:$password");
    my $token_response =  $self->{user_agent}->delete($url)->result->json;

    my $status = $token_response->{status};
    my $code = $token_response->{code};    
    
    if ($code != 200) {
        # say "Error removign user: $status : $code";
        return 0;
    }
    
    # say "Successfully removed user $username from server.";
    return 1;

}

1;