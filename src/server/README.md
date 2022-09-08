# Setting up dependencies 

The server application uses [Carton](https://metacpan.org/pod/Carton) Perl dependency manager. You can manually install the dependencies with ```cpanm [dependency_name]``` the hard way or just do:

```
cpanm Carton
carton install
```

It should be noted that Carton installs the dependencies to the ```./local``` directory so will need to use ```carton exec``` if running locally outside of a docker container. (Unless you installed the dependencies manually via cpanm)

# Running the Server

There are two ways to run the server application. You can either run locally via the ```morbo``` Mojolicious test server or via a Docker container. I tried to make this process as painless as possible for spinning up on new computers/servers.

## The "morbo" way

Simply type the following to spin up on localhost on port 3000:
```carton exec morbo RpgServer.pl```

## The "docker" way

For local deploys you can simply run ```./deploy_local_dev_server.sh``` this will build the docker image, stop any existing containers and spin up a new container with the new image. The rest service will be located at http://localhost:8082 You can change this port in the script if needed.

For remote deployments, build and push the image as you would in your environment. Make sure to configure the environment variables as needed on your host's settings. 

## Which way is preferred? 

None really. ```morbo``` is easier for development as the server will restart on file changes and doesn't require any Docker dependencies to be installed. For remote hosting, the Docker way is probably the the current only easy option.

