package Heap::Simple::Object;
require Heap::Simple::Wrapper;
require Heap::Simple::Method;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Method);
$VERSION = "0.02";
use strict;

sub _MAKE_KEY {
    my ($heap, $key, $value) = @_;
    return defined $heap->[0]{index} ? 
        $heap->[0]{complex} ? 
        "my \$meth = \$heap->[0]{index}; $key $value->\$meth" :
        "$key $value->_LITERAL" :
        qq(_CROAK "Element type 'Object' without key method");
}

sub key {
    my $heap = shift;
    if ($heap->[0]{complex}) {
        $heap->_make('sub key {
    my $heap = shift;
    _ELEMENTS_PREPARE()
    _MAKE_KEY(return, shift)}');
    } else {
        $heap->_make('sub key {
    return $_[1]->_LITERAL}');
    }
    return $heap->key(@_);
}

sub elements {
    return wantarray  && exists $_[0][0]{index} ? (Object => shift->[0]{index}) : "Object" ;
}

1;
