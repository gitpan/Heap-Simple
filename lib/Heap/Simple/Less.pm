package Heap::Simple::Less;
$VERSION = "0.01";
use strict;

sub _ORDER_PREPARE {
    return "my \$or_fun = \$self->[0][3];";
}

sub _SMALLER {
    return "\$or_fun->($_[1], $_[2])";
}

1;
