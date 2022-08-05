# rpg_net_perl
Somewhat of a Perl version of my other older "[rpg_net](https://github.com/shamrice/rpg_net)" project. This will probably get renamed to something real and restructured as time goes on.

There isn't much here yet. Once things start moving along (**IF** they do) this will be updated with some more detailed information.


## Perl CPAN packages required
This list may change on the fly...
* [Mojolicious](https://metacpan.org/dist/Mojolicious/view/script/mojo)
* [Data::UUID](https://metacpan.org/pod/Data::UUID)
* [Term::Screen](https://metacpan.org/pod/Term::Screen)
* [Time::HiRes](https://metacpan.org/pod/Time::HiRes)
* [Mime::Base64](https://metacpan.org/pod/MIME::Base64)


## Running test server

Run ```morbo ./RpgServer.pl``` from the ```src``` directory. This will set up a Mojolicious::Lite REST service for the clients to connect to.


## Running test client

In the ```src``` directory run ```./RpgClient.pl```. This will default connect to the server running on ```http://localhost:3000```. 

Multiple clients can be run from the same computer for testing.


