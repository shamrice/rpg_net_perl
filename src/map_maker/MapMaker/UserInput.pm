package MapMaker::UserInput;

use feature qw(say);
use Moo;

has screen => (
    is => 'ro',
    required => 1
);

sub blocking_getch {
    my $self = shift;
    my $char = $self->screen->getch;
    return $char;
}

sub getch {
    my $self = shift;

    my $char = ""; 
    if ($self->screen->key_pressed(0.1)) {        
        $char = $self->screen->getch;             
    }
    return $char;
}

sub get_string_input {
    my $self = shift;

    $self->screen->echo;

    my $output_str = "";
    my $cur_char = '';
    do {        
        $cur_char = $self->screen->getch;
        if ($cur_char ne "\r") {
            $output_str .= $cur_char;
        } elsif ($cur_char eq "kl") {
            chop($output_str);
        }
    } while ($cur_char ne "\r");
    
    chomp($output_str);    

    $self->screen->noecho;

    return $output_str;
}

1;
