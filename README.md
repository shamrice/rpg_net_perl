# rpg_net_perl
Somewhat of a Perl version of my other older "[rpg_net](https://github.com/shamrice/rpg_net)" project. This will probably get renamed to something real and restructured as time goes on.

There isn't much here yet. Once things start moving along (**IF** they do) this will be updated with some more detailed information.


## Perl CPAN packages used:
This list may change on the fly...
* [Mojolicious](https://metacpan.org/pod/Mojolicious)
* [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent)
* [Mojo::JSON](https://metacpan.org/pod/Mojo::JSON)
* [Moo](https://metacpan.org/pod/Moo)
* [Data::UUID](https://metacpan.org/pod/Data::UUID)
* [Term::Screen](https://metacpan.org/pod/Term::Screen)
* [Time::HiRes](https://metacpan.org/pod/Time::HiRes)
* [Mime::Base64](https://metacpan.org/pod/MIME::Base64)
* [Compress::LZW](https://metacpan.org/pod/Compress::LZW)
* [Config::Tiny](https://metacpan.org/pod/Config::Tiny)
* [Data::Dumper](https://metacpan.org/pod/Data::Dumper)
* [Carp](https://metacpan.org/pod/Carp)

## Running test server

Run ```morbo ./RpgServer.pl``` from the ```src``` directory. This will set up a Mojolicious::Lite REST service for the clients to connect to.


## Running test client

In the ```src``` directory run ```./RpgClient.pl```. This will default connect to the server running on ```http://localhost:3000```. 

Multiple clients can be run from the same computer for testing.


