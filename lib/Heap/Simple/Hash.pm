package Heap::Simple::Hash;
$VERSION = "0.01";
use strict;
use Carp;

sub _elements {
    my ($class, $self, $name, $elements) = @_;
    croak "missing key name for $elements->[0] elements" unless
        defined($elements->[1]);
    $self->[0][2] = $elements->[1];
    return $name;
}

sub _PREPARE {
    return "my \$name = \$self->[0][2];";
}

sub _KEY {
    return "$_[1] ->{\$name}";
}

sub min_key {
    my $self = shift;
    $self->_make('sub {
        my $self = shift;
    return @$self > 1 ? $self->[1]{$self->[0][2]} : _INF()
}');
    return $self->min_key(@_);
}

sub first_key {
    my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    return $self->[1]{$self->[0][2]};
}

sub key_name {
    return shift->[0][2];
}

1;
