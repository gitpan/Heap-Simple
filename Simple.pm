package Heap::Simple;
use strict;
use Carp;

use vars qw($VERSION $auto %used);
$VERSION = "0.02";
$auto = "Auto";
%used = ();

use AutoLoader qw(AUTOLOAD);

use constant DEBUG => 0;

sub _use {
    my $name = shift();
    $name =~ s|::|/|g;
    print STDERR "require Heap/Simple/$name.pm\n" if DEBUG;
    return require "Heap/Simple/$name.pm";
}

my %order = (""   => "Number",	# Default
            "<"	 => "Number",
            ">"	 => "NumberReverse",
            "lt" => "String",
            "gt" => "StringReverse",
             );
sub _order {
    my $order = $order{defined($_[1]) ? $_[1] : ""} ||
        croak "Unsupported order '$_[1]'";
    $used{$order} ||= _use($order);
    return $order;
}

sub _elements {
    my ($self, $elements) = @_;
    $elements = ["Key"] unless defined($elements);
    croak "option elements is not an array reference" unless
        ref($elements) eq "ARRAY";
    croak "option elements has no type defined at index 0" unless
        defined($elements->[0]);
    my $name = ucfirst(lc($elements->[0]));
    $used{$name} ||= _use($name);
    return (__PACKAGE__ . "::$name")->_elements($self, $name, $elements);
}

sub _init {
}

sub new {
    my ($class, %options) = @_;
    # note: the array starts at elements 1 to make the subscripting
    # operations (much!) cleaner.
    # So elements 0 is used for associated data
    my $self = bless [[undef, $options{user_data}]], $class;
    # We temporarily bless $self into $class so you can play OO games with it
    my $order   = $self->_order($options{order});
    my @elements = $self->_elements($options{elements});
    my $gclass = join("::", $class, $auto, $order, @elements);
    no strict "refs";
    @{"${gclass}::ISA"} = (__PACKAGE__ . "::$elements[0]",
                           __PACKAGE__ . "::$order",
                           $class) unless @{"${gclass}::ISA"};
    # Now rebless the result in its final generated class
    bless $self, $gclass;
    print STDERR "Generated class $gclass\n" if DEBUG;
    $self->_init(\%options);
    return $self;
}

sub _PREPARE {
    return "";
}

my $balanced;
# String with balanced parenthesis
$balanced = qr{[^()]*(?:\((??{$balanced})\)[^()]*)*};
sub _make {
    my $self  = shift;

    die "Cannot determine caller class from '$self'" unless ref($self);
    my $subroutine = (caller(1))[3];
    $subroutine =~ /(::[^:]*)\z/ || die "Cannot parse caller '$subroutine'";
    $subroutine = ref($self) . $1;
    print STDERR "Sub: $subroutine\n" if DEBUG;

    my $string = shift;
    # Very simple macro expander
    1 while $string =~ s/(_\w+)\(($balanced)\)/$self->$1(split ',', $2)/eg;
    print STDERR "Code: $string\n" if DEBUG;
    no warnings 'redefine';
    no strict 'refs';
    *$subroutine = eval $string;
    die $@ if $@;
}

sub first {
    return shift->[1];
}

sub count {
    return @{+shift}-1;
}

1;

__END__

sub insert {
    my $self = shift;
    if ($self->_KEY("") eq "") {
        $self->_make('sub {
    my ($self, $key) = @_;
    my $i = @$self;
    $i = $i >> 1 while $i > 1 && _SMALLER($key, ($self->[$i] = $self->[$i >> 1]));
    $self->[$i] = $key}');
    } else {
        $self->_make('sub {
    my ($self, $value) = @_;
    _PREPARE()
    my $key = _KEY($value);
    my $i = @$self;
    $i = $i >> 1 while
        $i > 1 && _SMALLER($key, _KEY(($self->[$i] = $self->[$i >> 1])));
    $self->[$i] = $value}');
    }
    $self->insert(@_);
}

sub extract_upto {
    my $self = shift;
    $self->_make('sub {
    my ($self, $border) = @_;
    _PREPARE()
    my @result;
    push(@result, $self->extract_min) until
        @$self <= 1 || _SMALLER($border, _KEY($self->[1]));
    return @result
}');
    $self->extract_upto(@_);
}

sub extract_min {
    my $self = shift;
    $self->_make('sub {
    my $self = shift;
    if (@$self <= 2) {
        return pop(@$self) if @$self == 2;
        croak "heap underflow";
    }
    my $min = $self->[1];
    _PREPARE()
    my $key = _KEY($self->[-1]);
    my $n = @$self-2;
    my $i = 1;
    my $l = 2;
    while ($l < $n) {
        if (_SMALLER(_KEY($self->[$l]), $key)) {
            if (_SMALLER(_KEY($self->[$l+1]), _KEY($self->[$l]))) {
                $self->[$i] = $self->[$l+1];
                $i = $l+1;
            } else {
                $self->[$i] = $self->[$l];
                $i = $l;
            }
        } elsif (_SMALLER(_KEY($self->[$l+1]), $key)) {
            $self->[$i] = $self->[$l+1];
            $i = $l+1;
        } else {
            last;
        }
        $l = $i * 2;
    }
    if ($l == $n && _SMALLER(_KEY($self->[$l]), $key)) {
        $self->[$i] = $self->[$l];
        $i = $l;
    }
    $self->[$i] = pop(@$self);
    return $min
}');
    $self->extract_min(@_);
}

# Often worth overriding
sub min_key {
    my $self = shift;
    croak "min_key not supported (no infinity) on ", ref($self) unless
        $self->can("_INF");
    $self->_make('sub {
    my $self = shift;
    _PREPARE()
    return @$self > 1 ? _KEY($self->[1]) : _INF()
}');
    $self->min_key(@_);
}

# Often worth overriding
sub first_key {
    my $self = shift;
    $self->_make('sub {
        my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    _PREPARE()
    return _KEY($self->[1])
}');
    return $self->first_key(@_);
}

sub user_data {
    if (@_ > 1) {
        my $self = shift;
        my $old = $self->[0][1];
        $self->[0][1] = shift;
        return $old;
    }
    return shift->[0][1];
}


=head1 NAME

Heap::Simple - A fast and simple classic heaps

=head1 SYNOPSIS

    use Heap::Simple;

    # Create a heap
    my $heap = Heap::Simple;
    my $heap = Heap::Simple->new(%options);

    # Put data in the hash
    $heap->insert($element);

    # Extract data
    $element = $heap->extract_min;

    # Extract all data whose key is not above a given value
    @elements = $heap->extract_upto($max_key);

    # Look which data is first without extracting
    $element = $heap->first;

    # Find the lowest value in the hep
    $min_key = $heap->first_key;  # returns undef   on an empty heap
    $min_key = $heap->min_key;	  # return infinity on an empty heap

    # Find the number of elements
    $count = $heap->count;

    # Get/Set user_data
    $user_data = $heap->user_data;
    $old_data  = $heap->user_data($new_data);

    # Get the position of a key in an element
    $key_index = $heap->key_index;
    $key_name  = $heap->key_name;

=head1 DESCRIPTION

A heap is a partially sorted structure where it's always easy to extract the
smallest element. If the collection of elements is changing dynamically, a
heap has less overhead than keeping the collection fully sorted.

The order in which equal elements get extracted is unspecified.

The main order relations supported by this module are "<" (numeric compare)
and "lt" (string compare).

The module allows you to manage data where the elements are of several
allowed types, in particular array references, hash references, objects
or just the keys themselves.

The internals of the module do nothing with the elements inserted except
inspecting the key. This means that if you for example store a blessed
object, that's what you will get back on extract. It's also ok to keep
references to the elements around and make changes to them while they are
in the heap as long as you don't change the key.

=head1 EXPORT

None.

=head1 METHODS

=over 4

=item X<new>my $heap = Heap::Simple->new

This simplest form creates a new (empty) heap object able to hold numeric keys.

You could for example use this to print a list of numbers from low to high:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->extract_min, " " for 1..$heap->count;
    print "\n";
    # Will print: -1 3 3 8 14

This example is silly of course. You could just as well directly use
L<perl sort|perlfunc/"sort">. But in real applications you would do the
inserting interleaved with extracting and always keeping the list sorted
would become inefficient for big lists. That is where you would use a heap.
The examples we give will however be like the one above so you can quickly
see the way in which the methods are supposed to be called.

For some applications this basic usage where you just store numeric keys will
be good enough, but usually you want to be able to store more complex elements.

Several options can help you with that:

=over 2

=item X<order>order => $order

$order indicates what operation is used to compare keys. Supported orders are:

=over 2

=item E<lt>

Indicates that keys are compared as numbers, and extraction is lowest value
first. This is actually the default order, so the example above could have
used:

    my $heap = Heap::Simple->new(order => "<");

and the result would have been exactly the same.

=item E<lt>

Indicates that keys are compared as numbers, and extraction is highest value
first. This means that methods like L<extract_min|"extract_min"> become 
rather confusing in name, since they extract the maximum in the sense of
the numeric value (but it's still the smallest value in terms of the 
abstract order relation).

Repeating the example with this order gives:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => ">");
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->extract_min, " " for 1..$heap->count;
    print "\n";
    # Will print: 14 8 3 3 -1

=item lt

Indicates that the keys are compared as strings, and extraction is lowest
value first. So we could modify the "<" example to:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt");
    $heap->insert($_) for "ate", 8, 3, "zzzz", 14, -1, 3, "at";
    print $heap->extract_min, " " for 1..$heap->count;
    print "\n";
    # Will print: -1 14 3 3 8 at ate zzzz

Notice how 14 comes before 3 as you would expect in lexical sorting.

=item gt

Indicates that the keys are compared as strings, and extraction is highest
value first. The concept of "minimum" again becomes rather confusing.
The standard example now becomes:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "gt");
    $heap->insert($_) for "ate", 8, 3, "zzzz", 14, -1, 3, "at";
    print $heap->extract_min, " " for 1..$heap->count;
    print "\n";
    # Will print: zzzz ate at 8 3 3 14 -1

=back

=item X<elements>elements => $element_type

This option describes what sort of elements we will store in the heap.
The only reason the module needs to know this is to determine how to access
the key values.

The following element types are currently supported:

=over 2

=item ["Key"]

Indicates that the elements are the keys themselves. This is the default if no
elements option is provided. So the constructor in the previous example could
also have been written as:

    my $heap = Heap::Simple->new(order => "lt", 
                                 elements => ["Key"]);

=item [Array => $index]

Indicates that the elements are array references, with the key at index $index.
So now the element can be not just the key, but also associated data. We can
use this to for example print the values of a hash ordered by key:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt", 
                                 elements => [Array => 0]);
    while (my ($key, $val) = each %hash) {
        $heap->insert([$key, $val]);
    }
    for (1..$heap->count) {
        print $heap->extract_min->[1], "\n";
    }

You can always use something like [$key, @data] to pair up keys and data,
so the "Array" element type is rather generally useful. Since it's so common
to put the key in the first position, you may in fact drop the index in that
case, so the constructor in the previous example could also be written as:

    my $heap = Heap::Simple->new(order => "lt", 
                                 elements => ["Array"]);

In case the elements you want to store are array (or array based objects
(or L<fields based objects|fields>) and you are prepared to break the object
encapsulation), this element type is also very nice. If for example the value
on which you want to order is a number at position 4, you could use:

    my $heap = Heap::Simple->new(elements => [Array => 4]);
    print "The key is $object->[4]\n";
    $heap->insert($object);

=item [Hash => $key_name]

Indicates that the elements are hash references, where the key (for the heap
element) is the value $element->{$key_name} .

Redoing the Array example in Hash style gives:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt", 
                                 elements => [Hash => "tag"]);
    while (my ($key, $val) = each %hash) {
        $heap->insert({tag => $key, value => $val});
    }
    for (1..$heap->count) {
        print $heap->extract_min->{value}, "\n";
    }

In case the elements you want to store are hashes (or based objects and you
are prepared to break the object encapsulation), this element type is also
very nice. If for example the value on which you want to order is a number
with key "price", you could use:

    my $heap = Heap::Simple->new(elements => [Hash => "price"]);
    print "The key is $object->{price}\n";
    $heap->insert($object);

=back

=item user_data => $user_data

You can associate one scalar worth of user data with any heap. This option
allows you to set its value already at object creation. You can use the
L<user_data|"user_data"> method to get/set the associated value.

If this option is not given, the heap starts with "undef" associated to it.

    my $heap = Heap::Simple->new(user_data => "foo");
    print $heap->user_data, "\n";
    # prints foo

=back

=item X<insert>$heap->insert($element)

Inserts the $element in the heap. On extraction you get back exactly the same
$array_ref as you inserted, including a possible L<blessing|perlfunc/"bless">.

=item X<extract_min>$element = $heap->extract_min

For all elements in the heap, find the one with the lowest key, remove it from
the heap and return it.

Throws an exception if the heap is empty.

=item X<extract_upto>@elements = $heap->extract_upto($value)

Finds all elements in the heap whose key is not above $value and removes them
from the heap. The list of removed element is returned ordered by key value
(low to high).

Returns an empty list for the empty heap.

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print join(", ", $heap->extract_upto(3)), "\n";
    # prints -1, 3, 3

=item X<min>$element = $heap->first

For all elements in the heap, find the one with the lowest key and return it.
Returns undef in case the heap is empty. The contents of the heap remain
unchanged.

Since the data returned from a non-empty heap can usually not be undef, you
could use this method to check if a heap is empty, but it's probably more
natural to use L<count|"count"> for that.

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->first, "\n";
    # prints -1

=item X<first_key>$min_key = $heap->first_key

Looks for the lowest key in the heap and returns its value. Returns undef
in case the heap is empty

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->first_key, "\n";
    # prints -1

=item X<min_key>$min_key = $heap->min_key

Looks for the lowest key in the heap and returns its value. Returns the highest
possible value (the infinity for the chosen order) in case the heap is empty. 
This method does not exist for heap types whose keys have no (repesentable) 
highest value (like order => "lt").

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->min_key, "\n";
    # prints -1

=item X<count>$count = $heap->count

Returns the number of elements in the heap.

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->count, "\n";
    # prints 5

=item X<user_data>$user_data = $heap->user_data

Queries the user_data associated with the heap.

=item $old_data = $heap->user_data($new_data)

Associates new user_data with the heap. Returns the old value.

=item $key_index = $heap->key_index

Returns the index of the key for array reference based heaps. Doesn't exist
for the other heap types.

=item $key_name = $heap->key_name

Returns the name of the key key for hash reference based heaps. Doesn't exist
for the other heap types.

=back

=head1 SEE ALSO

L<Heap>,
L<Heap::Priority>

=head1 AUTHOR

Ton Hospel, E<lt>Heap::Simple@home.lunixE<gt>

Parts are based on code by Joseph N. Hall (http://www.perlfaq.com/faqs/id/196)

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
