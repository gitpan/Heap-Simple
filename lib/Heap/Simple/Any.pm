package Heap::Simple::Any;
require Heap::Simple::Wrapper;
require Heap::Simple::Function;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Function);
$VERSION = "0.02";
use strict;

sub _MAKE_KEY {
    my ($heap, $key, $value) = @_;
    return defined $heap->[0]{index} ? "$key \$heap->[0]{index}->($value)" :
        qq(_CROAK "Element type 'Any' without key code");
}

sub elements {
    return wantarray && exists $_[0][0]{index} ? (Any => shift->[0]{index}) : "Any";
}

1;
