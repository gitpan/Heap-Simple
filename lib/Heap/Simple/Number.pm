package Heap::Simple::Number;
$VERSION = "0.02";
use strict;

sub _SMALLER {
    return "$_[1] < $_[2]";
}

sub _INF {
    return 1e5000000000;
}

1;
