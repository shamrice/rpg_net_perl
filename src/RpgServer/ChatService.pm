package RpgServer::ChatService;

use strict;
use warnings FATAL => 'all';

use POSIX;
use Moo;

use constant (
    MAX_CHAT_QUEUE_LENGTH => 10
);

my $log = Mojo::Log->new;

has chat_queue => (
    is => 'rwp'
);

sub add_message {
    my ($self, $user_name, $text) = @_;
    chomp($user_name);
    chomp($text);

    my $date_str = strftime("%H:%M:%S", localtime);

    my $chat_text = "[$date_str $user_name]: $text";

    if (not defined $self->chat_queue) {
        $self->_set_chat_queue([ ]);
    }
    my $removed_text = "";
    if (scalar(@{$self->chat_queue}) > MAX_CHAT_QUEUE_LENGTH) {
        $removed_text = shift(@{$self->chat_queue});
    }
    push @{$self->chat_queue}, $chat_text;

    $log->info("Removed oldest chat text: $removed_text :: Added: $chat_text");
}

sub get_messages {
    my $self = shift;

    if (not defined $self->chat_queue) {
        $self->_set_chat_queue([ ]);
    }
    return $self->chat_queue;
}



1;