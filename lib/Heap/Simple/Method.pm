package Heap::Simple::Method;
$VERSION = "0.01";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    croak "missing key method for object elements" unless
        defined($elements->[1]);
    $self->[0][2] = $elements->[1];
    return $name;
}

sub _PREPARE {
    return "my \$name = \$self->[0][2];";
}

sub _KEY {
    return "$_[1] ->\$name";
}

sub key_method {
    return shift->[0][2];
}

1;
