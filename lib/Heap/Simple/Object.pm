package Heap::Simple::Object;
require Heap::Simple::Wrapper;
require Heap::Simple::Method;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Method);
$VERSION = "0.01";
use strict;

sub _MAKE_KEY {
    my ($self, $key, $value) = @_;
    return "my \$meth = \$self->[0][2]; $key $value->\$meth";
}

1;
