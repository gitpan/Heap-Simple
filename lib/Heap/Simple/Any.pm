package Heap::Simple::Any;
require Heap::Simple::Wrapper;
require Heap::Simple::Function;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Function);
$VERSION = "0.01";
use strict;

sub _MAKE_KEY {
    my ($self, $key, $value) = @_;
    return "$key \$self->[0][2]->($value)";
}

1;
