package Heap::Simple::Function;
$VERSION = "0.03";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    croak "missing key function for elements $self" unless
        defined($elements->[1]) || $class->isa("Heap::Simple::Wrapper");
    $self->[0][2] = $elements->[1];
    return $name;
}

sub _ELEMENTS_PREPARE {
    return "my \$el_fun = \$self->[0][2];";
}

sub _KEY {
    return "\$el_fun->($_[1])";
}

sub _QUICK_KEY {
    return "\$self->[0][2]->($_[1])";
}

sub key_function {
    return shift->[0][2];
}

sub key {
    return $_[0][0][2]->($_[1]);
}


1;
