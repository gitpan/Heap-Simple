package Heap::Simple::Hash;
$VERSION = "0.03";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    croak "missing key name for $elements->[0] elements" unless
        defined($elements->[1]);
    $self->[0][2] = $elements->[1];
    return $name;
}

sub _ELEMENTS_PREPARE {
    return "my \$name = \$self->[0][2];";
}

sub _KEY {
    return $_[1] . "->{\$name}";
}

sub _QUICK_KEY {
    return $_[1] . "->{\$self->[0][2]}"
}

sub key_name {
    return shift->[0][2];
}

sub key {
    return $_[1]->{$_[0][0][2]};
}

1;
