package Heap::Simple::Wrapper;
$VERSION = "0.03";
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
    my $heap = shift;
    $heap->_make('sub key_insert {
    my $heap = shift;
    my $key  = shift;
    _PREPARE()
    my $i = @$heap;
    _MAX_COUNT(if ($i > _MAX_COUNT) {
        return unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->e_recover($l, $min);)
    $heap->[$l >> 1] = _WRAPPER($key, shift);
    return;})
    _CAN_DIE(eval {)
    $i = $i >> 1 while 
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->i_recover($i);)
    $heap->[$i] = _WRAPPER($key, shift);
    return};
    ');
    $heap->key_insert(@_);
}

sub _key_insert {
    my $heap = shift;
    $heap->_make('sub _key_insert {
    my $heap = shift;
    my $key  = $_[0][0];
    _PREPARE()
    my $i = @$heap;
    _MAX_COUNT(if ($i > _MAX_COUNT) {
        return unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->e_recover($l, $min);)
    $heap->[$l >> 1] = shift;
    return;})
    _CAN_DIE(eval {)
    $i = $i >> 1 while 
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->i_recover($i);)
    $heap->[$i] = shift;
    return};
    ');
    $heap->_key_insert(@_);
}

sub _key_absorb {
    my ($from, $to) = @_;
    Carp::croak "Self absorption" if $from == $to;
    while (@$from > 1) {
        $to->_key_insert($from->[-1]);
        pop @$from;
    }
}

sub wrapped {
    return 1;
}

1;
