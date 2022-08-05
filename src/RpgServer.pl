#!/usr/bin/perl

use Mojolicious::Lite; 
use Mojo::JSON qw(encode_json decode_json);
use feature qw(say);


use RpgServer::User;
use RpgServer::Authorization; 

use strict;
use warnings;

#TODO : make configurable
use constant SERVER_KEY => "B2F55FE4-B9FD-421E-8764-51CBC323E36C";
use constant PLAYER_TIMEOUT_SECONDS => 60;

#TODO : admin remove player endpoint and also a similar endpoint where players can remove themselves.

my $log = Mojo::Log->new;
my %user_hash;
my $auth_service = RpgServer::Authorization->new;

$log->info("Server starting up");


post '/rest/user/add/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');
    
    if (!$auth_service->validate_auth($self->req->headers->authorization, $id)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    }

    # TODO : validate that the values sent in are sane / valid.

    my $data = decode_json($self->req->body);
    $log->info("JSON data: $data");     
    my $name = $data->{'name'};
    my $user_char = $data->{'user_char'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
 
    if (exists $user_hash{$id}) {
        $log->warn("Tried to add already existing user: $id");
        my $error_response = {
            id => $id, 
            status => "User already added", 
            code => 400
        };
        return $self->render(json => $error_response, status => 400);
    }


    $log->info("Adding user id: $id :: name: $name : user_char: $user_char : x: $x : y: $y");
    
    my $new_user = RpgServer::User->new($id, $name, $user_char, $x, $y);

    $user_hash{$id} = $new_user;

    my $response = {
        userId => $id, 
        status => "Success",
        code => "200"
    };
    $self->render(json => $response);
}; 
 

get '/rest/users' => sub {
    my $self = shift;    

    if (!$auth_service->validate_auth($self->req->headers->authorization)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    } 
 
    my $num_current_users = keys %user_hash;
    $log->info("Current number of found users: $num_current_users");

    my $user_list = [ ];
    foreach my $user (keys %user_hash) {

        my $found_user = $user_hash{$user};

        #$log->info("Found user: $found_user");

        if (time() - $found_user->{last_activity} > PLAYER_TIMEOUT_SECONDS) {
            $log->info("User: $user has timed out and will be removed from the server.");
            delete $user_hash{$user};
            next;
        }
        
        push @$user_list, { 
            id => $found_user->{id}, 
            name => $found_user->{name},
            user_char => $found_user->{user_char},
            x => $found_user->{x},
            y => $found_user->{y}
        }; 
    }

    my $users_response = {
        status => "Success",        
        code => 200,
        users => $user_list
    };

    $self->render(json => $users_response); 
 

};



get '/rest/user/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');

    if (!$auth_service->validate_auth($self->req->headers->authorization)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    } 
 
    if (not exists $user_hash{$id}) {
        my $error_response = {
            id => $id, 
            status => "User not found",
            code => 404
        };
        return $self->render(json => $error_response, status => 404);
    } 

    my $found_user = $user_hash{$id};

    my $user = {
        id => $found_user->{id},
        name => $found_user->{name},
        user_char => $found_user->{user_char},
        x => $found_user->{x},
        y => $found_user->{y}
    };

    $self->render(json => $user);
};


put '/rest/user/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');

        
    if (!$auth_service->validate_auth($self->req->headers->authorization, $id)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    }

    # TODO : validate that the values sent in are sane / valid.

    my $data = decode_json($self->req->body);
    $log->info("JSON data: $data");     
    my $name = $data->{'name'};
    my $user_char = $data->{'user_char'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
 
    if (not exists $user_hash{$id}) {
        $log->warn("Tried to update a user that doesn't exist: $id");
        my $error_response = {
            id => $id, 
            status => "User does not exist", 
            code => 400
        };
        return $self->render(json => $error_response, status => 400);
    }

    $log->info("Updating user id: $id :: name: $name : user_char: $user_char : x: $x : y: $y");
       

    $user_hash{$id}->update($x, $y, $name, $user_char);

    my $response = {
        userId => $id, 
        status => "Success",
        code => "200"
    };
    $self->render(json => $response);
};



get '/rest/token/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');

    my $basic_auth = $self->req->headers->authorization;    

    if (!$auth_service->validate_token_auth($basic_auth, $id)) {
        my $error_response = {    
            status => "Unauthorized",
            code => 401
        };
        return $self->render(json => $error_response, status => 401);
    }

    my $new_token = $auth_service->generate_token($id);

    my $tokenResponse = {
        userId => $id, 
        token => $new_token,
        status => "Success",
        code => 200
    };

    $self->render(json => $tokenResponse);
};




app->start;

