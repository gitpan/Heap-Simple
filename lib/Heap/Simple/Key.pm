package Heap::Simple::Key;
$VERSION = "0.02";
use strict;

sub _KEY {
    return $_[1];
}

sub _elements {
    return $_[2];	# Just the name
}

sub first_key {
    return shift->[1];
}

1;
