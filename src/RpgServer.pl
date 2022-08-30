#!/usr/bin/perl
package RpgServer;

use Mojolicious::Lite; 
use Mojo::JSON qw(encode_json decode_json);
use Compress::LZW;
use MIME::Base64;
use Data::Dumper;

use RpgServer::Configuration;
use RpgServer::AuthorizationService; 
use RpgServer::UserService;
use RpgServer::ChatService;

use feature qw(say);
use strict;
use warnings;

=head3 Usage
    Set env vars if needed.
    RPG_DUMP_CONFIG=1 RPG_SERVER_CONFIG=/some/config.conf  morbo ./RpgServer.pl
=cut

 
#TODO : admin remove player endpoint and also a similar endpoint where players can remove themselves.

my $log = Mojo::Log->new;

my $config_file = "./RpgServer/conf/server.conf";
my $dump_config = 0;
if (defined $ENV{RPG_SERVER_CONFIG}) {
    $config_file = $ENV{RPG_SERVER_CONFIG};
}
if (defined $ENV{RPG_DUMP_CONFIG}) {
    $dump_config = 1;
}
say Dumper \%ENV;
$log->info("Using configuration file: $config_file");

my $config = RpgServer::Configuration::get_config($config_file, $dump_config);
my $auth_service = RpgServer::AuthorizationService->new(config => $config->{authorization_service});
my $user_service = RpgServer::UserService->new(config => $config->{user_service});
my $chat_service = RpgServer::ChatService->new(config => $config->{chat_service});

$log->info("Server starting up");


# debug loading of test map...
# TODO : move this into its own module.
my @map = ( );
 
my $map_world = 0;
my $map_y = 0;
my $map_x = 0; 
# my $map_filename = $map_world.$map_y.$map_x.".map";
my @map_files = ("000.map", "001.map", "010.map");

foreach my $map_filename (@map_files) {
    my $map_data_raw;
    open(MAP_FH, '<', $config->{data}{MAP_DIRECTORY} . $map_filename) or die "Cannot load test map data : $!\n";
    while (<MAP_FH>) {
        my $row = $_;
        chomp($row);
        if ($row !~ m/^#.*/) {                
            $map_data_raw .= $row;
        }  
    }

    $map_x = int(substr($map_filename, 1, 1));
    $map_y = int(substr($map_filename, 2, 1));
    say "filename: $map_filename map xy: $map_x,$map_y";
    
    # map data is stored in memory and sent as base64 encoded LZW compressed version of the raw data to decrease response size.
    my $compressed_map_data = compress($map_data_raw);
    $compressed_map_data = encode_base64($compressed_map_data);
    chomp($compressed_map_data);
    $map[$map_world][$map_x][$map_y] = $compressed_map_data;

    close(MAP_FH);
}

# my $enemy_filename = "enemy_".$map_world.$map_y.$map_x.".json";

$map_y = 0;

my @enemy_files = ("enemy_000.json", "enemy_001.json");

foreach my $enemy_filename (@enemy_files) {

    open(ENEMY_FH, '<', $config->{data}{ENEMIES_DIRECTORY} . $enemy_filename) or die "Cannot load enemy data: $!\n";
    my $enemy_json_data;
    while (<ENEMY_FH>) {
        my $row = $_;
        chomp($row);
        $enemy_json_data .= $row;
    }
    say "Read enemy json data: $enemy_json_data";
 
    my $full_data = decode_json($enemy_json_data);
    foreach my $data (@$full_data) {
        $log->info("JSON data: $data");   
        my $id = $data->{'id'} ;
        my $name = $data->{'name'};
        my $user_char = $data->{'user_char'};
        my $map_x = $data->{'map_x'};
        my $map_y = $data->{'map_y'};
        my $x = $data->{'x'};
        my $y = $data->{'y'};
    
  
        $user_service->add_user($id, $name, $user_char, $map_x, $map_y, $x, $y);
    }
  
    close(ENEMY_FH);  
}
    
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
    my $map_x = $data->{'map_x'};
    my $map_y = $data->{'map_y'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
     
 
    if (!$user_service->add_user($id, $name, $user_char, $map_x, $map_y, $x, $y)) {         
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
    return $self->render(json => $response);
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

    return $self->render(json => $users_response); 
 
};

  
get '/rest/users/:world_id/:map_x/:map_y' => sub {
    my $self = shift;    
    my $world_id = $self->param('world_id');
    my $map_x = $self->param('map_x');
    my $map_y = $self->param('map_y');

    if (!$auth_service->validate_auth($self->req->headers->authorization)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    } 

    my $user_list = $user_service->get_users_at($world_id, $map_x, $map_y);

    my $users_response = {
        status => "Success",        
        code => 200,
        users => $user_list
    };

    return $self->render(json => $users_response); 
 
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
        return $self->render(json => $found_user);
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
    my $map_x = $data->{'map_x'};
    my $map_y = $data->{'map_y'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};

    if ($user_service->update_user($id, $name, $user_char, $map_x, $map_y, $x, $y)) {
        my $response = {
            userId => $id, 
            status => "Success",
            code => "200"
        };
        return $self->render(json => $response);
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
        return $self->render(json => $response);
    } else {
        my $error_response = {
            id => $id, 
            status => "User does not exist", 
            code => 400
        };  
        return $self->render(json => $error_response, status => 400);     
    }
};

 
get '/rest/map/:world_id/:x/:y' => sub {
    my $self = shift;
    my $world_id = $self->param('world_id');
    my $world_x = $self->param('x');
    my $world_y = $self->param('y');

    if (!$auth_service->validate_auth($self->req->headers->authorization)) {
        my $error_response = {            
            status => "Unauthorized",
            code => 401
        };  
        return $self->render(json => $error_response, status => 401);
    }   
 
    if (!exists($map[$world_id][$world_x][$world_y])) {
        $log->info("Map data not found at $world_id, $world_x, $world_y");
        my $data_not_found = {
            status => "Map data not found",
            code => 404,            
        };

        return $self->render(json => $data_not_found, status => 404);
    }

    $log->info("Returning raw map data: ".$map[$world_id][$world_x][$world_y]);

    my $world_data_response = {
        status => "Success",
        code => 200,        
        data => $map[$world_id][$world_x][$world_y]
    };

    return $self->render(json => $world_data_response);

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

    return $self->render(json => $tokenResponse);
};



get '/rest/chat' => sub {
    my $self = shift;

    if (!$auth_service->validate_auth($self->req->headers->authorization)) {
        my $error_response = {
            status => "Unauthorized",
            code => 401
        };
        return $self->render(json => $error_response, status => 401);
    }

    my $chat_messages = $chat_service->get_messages;

    my $chat_response = {
        status => "Success",
        code => 200,
        chat_log => $chat_messages
    };

    $log->info("Returning chat log response: " . Dumper \$chat_response);

    return $self->render(json => $chat_response);

};


post '/rest/chat/add/:id' => sub {
    my $self = shift;
    my $id = $self->param('id');

    if (!$auth_service->validate_auth($self->req->headers->authorization, $id)) {
        my $error_response = {
            status => "Unauthorized",
            code => 401
        };
        return $self->render(json => $error_response, status => 401);
    }

    my $found_user = $user_service->get_user($id);
    if (not defined $found_user) {
        my $error_response = {
            id => $id,
            status => "User not found",
            code => 404
        };
        return $self->render(json => $error_response, status => 404);
    }

    my $data = decode_json($self->req->body);
    $log->info("JSON data: " . Dumper \$data);
    my $chat_text = $data->{'text'};
    my $chat_name = $found_user->{name};

    $chat_service->add_message($chat_name, $chat_text);

    my $chat_response = {
        status => "Success",
        code => 200
    };
    return $self->render(json => $chat_response);

};

app->start;

