#!/usr/bin/perl
package RpgServer;

use Mojolicious::Lite; 
use Mojo::JSON qw(encode_json decode_json);
use feature qw(say);

use RpgServer::AuthorizationService; 
use RpgServer::UserService; 

use strict;
use warnings;


#TODO : admin remove player endpoint and also a similar endpoint where players can remove themselves.

my $log = Mojo::Log->new;
my $auth_service = RpgServer::AuthorizationService->new;
my $user_service = RpgServer::UserService->new;

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

 
    my $data = decode_json($self->req->body);
    $log->info("JSON data: $data");     
    my $name = $data->{'name'};
    my $user_char = $data->{'user_char'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
     
 
    if (!$user_service->add_user($id, $name, $user_char, $x, $y)) {         
        my $error_response = {
            id => $id, 
            status => "User already added", 
            code => 400
        };
        return $self->render(json => $error_response, status => 400);        
    }


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

    my $user_list = $user_service->get_users;

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
 

    my $found_user = $user_service->get_user($id);
    if (defined $found_user) {
        $self->render(json => $found_user);
    } else {
        my $error_response = {
            id => $id, 
            status => "User not found",
            code => 404
        };
        return $self->render(json => $error_response, status => 404);
    }
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

    my $data = decode_json($self->req->body);
    $log->info("JSON data: $data");     
    my $name = $data->{'name'};
    my $user_char = $data->{'user_char'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};

    if ($user_service->update_user($id, $name, $user_char, $x, $y)) {
        my $response = {
            userId => $id, 
            status => "Success",
            code => "200"
        };
        $self->render(json => $response);
    } else {
        my $error_response = {
            id => $id, 
            status => "User does not exist", 
            code => 400
        };  
        return $self->render(json => $error_response, status => 400);        
    }

};


 
del '/rest/user/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');

    if (!$auth_service->validate_auth($self->req->headers->authorization, $id)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    }   

    if ($user_service->remove_user($id)) {
 
        my $response = {
            userId => $id, 
            status => "Success",
            code => "200"
        };
        $self->render(json => $response);
    } else {
        my $error_response = {
            id => $id, 
            status => "User does not exist", 
            code => 400
        };  
        return $self->render(json => $error_response, status => 400);     
    }
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
