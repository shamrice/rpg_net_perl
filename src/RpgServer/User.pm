#!/usr/bin/perl
package RpgServer::User;

use Data::UUID;
use strict;
use warnings;

sub new {    
    my ($class, $id, $name, $user_char, $x, $y) = @_;

    my $self = { 
        id => $id,  
        name => $name,      
        user_char => $user_char,
        x => $x,
        y => $y,
        last_activity => time()
    };
    bless $self, $class;    
}

sub update {
    my ($self, $x, $y, $name, $user_char) = @_;
    if (defined $x) {        
        $self->{x} = $x;        
    }
    if (defined $y) {        
        $self->{y} = $y;
    }
    if (defined $name) {
        $self->{name} = $name;
    }
    if (defined $user_char) {
        $self->{user_char} = $user_char;
    }   

    $self->{last_activity} = time(); 
}

sub get_id {
    my $self = shift;
    return $self->{id};
}

sub to_string {
    my $self = shift;
    my $id = $self->{id};
    my $name = $self->{name};
    my $user_char = $self->{user_char};
    my $x = $self->{x};
    my $y = $self->{y};
    my $last_activity = $self->{last_activity};

    return "User id: $id :: name: $name :: user_char: $user_char :: x: $x :: y: $y :: last_activity: $last_activity";
}

1;