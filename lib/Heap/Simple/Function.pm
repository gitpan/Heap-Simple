package Heap::Simple::Function;
$VERSION = "0.01";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    croak "missing key function for elements" unless
        defined($elements->[1]);
    $self->[0][2] = $elements->[1];
    return $name;
}

sub _PREPARE {
    return "my \$fun = \$self->[0][2];";
}

sub _KEY {
    return "\$fun->($_[1])";
}

sub min_key {
    my $self = shift;
    croak "min_key not supported (no infinity) on ", ref($self) unless
        $self->can("_INF");
    $self->_make('sub {
        my $self = shift;
    return @$self > 1 ? $self->[0][2]->($self->[1]) : _INF()
}');
    return $self->min_key(@_);
}

sub first_key {
    my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    return $self->[0][2]->($self->[1]);
}

sub key_function {
    return shift->[0][2];
}

1;
