package Heap::Simple::String;
$VERSION = "0.01";
use strict;

sub _SMALLER {
    return "$_[1] lt $_[2]";
}

1;
