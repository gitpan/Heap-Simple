package Heap::Simple::Array;
$VERSION = "0.02";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    if (defined($elements->[1])) {
        $elements->[1] =~ /^\s*(-?\d+)\s*$/ || croak "index '$elements->[1]' for $elements->[0] elements is not an integer";
        $self->[0][2] = $1+0;
    } else {
        $self->[0][2] = 0;
    }
    return $name, $self->[0][2];
}

sub _KEY {
    return $_[1] . "->[$_[0][0][2]]";
}

sub _QUICK_KEY {
    return $_[1] . "->[\$self->[0][2]]"
}

sub key_index {
    my $self = shift;
    $self->_make("sub {
    return $self->[0][2];
}");
    return $self->key_index(@_);
}

sub key {
    return $_[1]->[$_[0][0][2]];
}

1;
