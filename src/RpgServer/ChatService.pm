package RpgServer::ChatService;

use strict;
use warnings FATAL => 'all';

use POSIX;
use Moo;

my $log = Mojo::Log->new;

has config => (
    is       => 'ro',
    required => 1
);

has chat_queue => (
    is => 'rwp'
);

sub add_message {
    my ($self, $user_name, $text) = @_;
    chomp($user_name);
    chomp($text);

    if (length $text >= $self->config->{MAX_CHAT_TEXT_LENGTH}) {
        $log->info("New chat text length from $user_name too long. Text to be truncated: $text");
        $text = substr($text, 0, $self->config->{MAX_CHAT_TEXT_LENGTH});
    }

    my $date_str = strftime("%H:%M:%S", localtime);

    my $chat_text = "[$date_str $user_name]: $text";

    if (not defined $self->chat_queue) {
        $self->_set_chat_queue([ ]);
    }
    my $removed_text = "";
    if (scalar(@{$self->chat_queue}) >= $self->config->{MAX_CHAT_QUEUE_LENGTH}) {
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