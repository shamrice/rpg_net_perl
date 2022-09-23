#!/usr/bin/perl
package RpgServer;

use feature qw(say);
use strict;
use warnings;

use Mojolicious::Lite; 
use Mojo::JSON qw(encode_json decode_json);
use Compress::LZW;
use MIME::Base64;
use Data::Dumper;
use FindBin;

use lib "$FindBin::Bin/";

use RpgServer::Configuration;
use RpgServer::AuthorizationService; 
use RpgServer::UserService;
use RpgServer::ChatService;


=head3 Usage
    Set env vars if needed.
    RPG_DUMP_CONFIG=1 RPG_SERVER_CONFIG=/some/config.conf  morbo ./RpgServer.pl
=cut

#TODO : admin remove player endpoint and also a similar endpoint where players can remove themselves.

my $log = Mojo::Log->new;

$log->debug("Server started with command line: $0 @ARGV");
 
my $config_file = "$FindBin::Bin/RpgServer/conf/server.conf";
my $dump_config = 0;
if (defined $ENV{RPG_SERVER_CONFIG}) {
    $config_file = $ENV{RPG_SERVER_CONFIG};
}
if (defined $ENV{RPG_DUMP_CONFIG}) {
    $dump_config = 1;
}
$log->debug("Environment vars: " . Dumper \%ENV);
$log->info("Using configuration file: $config_file");

my $config = RpgServer::Configuration::get_config($config_file, $dump_config);
my $auth_service = RpgServer::AuthorizationService->new(config => $config->{authorization_service});
my $user_service = RpgServer::UserService->new(config => $config->{user_service});
my $chat_service = RpgServer::ChatService->new(config => $config->{chat_service});

 
my @map = load_map_data(); 
load_enemy_data(); 
 
 
sub load_map_data {

    my @map = ( );
 
    my @map_files = glob($config->{data}{MAP_DIRECTORY} . "*.map"); 

    $log->info("Map data files: @map_files");

    foreach my $map_file (@map_files) {
        my $map_data_raw;
        open(my $MAP_FH, '<', $map_file) or die "Cannot load test map data : $!\n";
        while (<$MAP_FH>) {
            my $row = $_;
            chomp($row);
            if ($row !~ m/^#.*/) {                
                $map_data_raw .= $row;
            }  
        }
        close($MAP_FH);

        (my $map_filename = $map_file) =~ s/^.*\///;
        $map_filename =~ s/\.map//;
        my @map_coords = split("_", $map_filename);

        $log->debug("stripped filename: $map_filename => map wxy: @map_coords");
    
        # map data is stored in memory and sent as base64 encoded LZW compressed version of the raw data to decrease response size.
        my $compressed_map_data = compress($map_data_raw);
        $compressed_map_data = encode_base64($compressed_map_data);
        chomp($compressed_map_data);
        $map[$map_coords[0]][$map_coords[1]][$map_coords[2]] = $compressed_map_data;
    
    }

    return @map;
}


sub load_enemy_data {

    my @enemy_files = glob($config->{data}->{ENEMIES_DIRECTORY} . "*.json"); 

    $log->info("Enemy data files: @enemy_files");

    foreach my $enemy_filename (@enemy_files) {

        open(my $ENEMY_FH, '<', $enemy_filename) or die "Cannot load enemy data: $!\n";
        my $enemy_json_data;
        while (<$ENEMY_FH>) {
            my $row = $_;
            chomp($row);
            $enemy_json_data .= $row;
        }
        close($ENEMY_FH);  

        say "Read enemy json data: $enemy_json_data";
 
        my $full_data = decode_json($enemy_json_data);

        foreach my $data (@$full_data) {
            $log->info("JSON data: $data");   
            my $id = $data->{'id'} ;
            my $name = $data->{'name'};
            my $user_char = $data->{'user_char'};
            my $world_id = $data->{'world_id'};
            my $map_x = $data->{'map_x'};
            my $map_y = $data->{'map_y'};
            my $x = $data->{'x'};
            my $y = $data->{'y'};
  
            $user_service->add_user($id, $name, $user_char, $world_id, $map_x, $map_y, $x, $y);
        }
    }
    
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
    my $world_id = $data->{'world_id'};
    my $map_x = $data->{'map_x'};
    my $map_y = $data->{'map_y'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
     
 
    if (!$user_service->add_user($id, $name, $user_char, $world_id, $map_x, $map_y, $x, $y)) {         
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
    $log->trace("JSON data: " . Dumper \$data);     

    my $name = $data->{'name'};
    my $user_char = $data->{'user_char'};
    my $world_id = $data->{'world_id'};
    my $map_x = $data->{'map_x'};
    my $map_y = $data->{'map_y'};
    my $x = $data->{'x'};
    my $y = $data->{'y'};
 
    if ($user_service->update_user($id, $name, $user_char, $world_id, $map_x, $map_y, $x, $y)) {
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


get '/' => sub {
    my $self = shift;
    $self->render('index');


};


$log->info("Server starting up");
app->start;
 

__DATA__
@@ index.html.ep
% layout 'default';
% title 'Perl RPG Test Server';
<p>Perl RPG Server is online</p>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <meta charset="utf-8">    
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body>
    <%= content %>    
  </body>
</html>
