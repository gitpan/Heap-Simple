package Heap::Simple::Wrapper;
$VERSION = "0.02";
use strict;

sub _ELEMENTS_PREPARE {
    return "";
}

sub _QUICK_KEY {
    return shift->_KEY(@_);
}

sub _KEY {
    return $_[1] . "->[0]";
}

sub _VALUE {
    return $_[1] . "->[1]";
}

sub _WRAPPER {
    return "[$_[1], $_[2]]";
}

sub key_insert {
    my $self = shift;
    $self->_make('sub {
    my $self = shift;
    my $key  = shift;
    _PREPARE()
    my $i = @$self;
    $i = $i >> 1 while
        $i > 1 && _SMALLER($key, _KEY(($self->[$i] = $self->[$i >> 1])));
    $self->[$i] = _WRAPPER($key, shift);
    return};
    ');
    $self->key_insert(@_);
}

1;
