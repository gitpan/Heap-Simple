package Heap::Simple::StringReverse;
$VERSION = "0.01";
use strict;

sub _SMALLER {
    return "$_[1] gt $_[2]";
}

sub _INF {
    return "''";
}

1;
