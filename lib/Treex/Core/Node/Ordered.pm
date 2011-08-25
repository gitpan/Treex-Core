package Treex::Core::Node::Ordered;
BEGIN {
  $Treex::Core::Node::Ordered::VERSION = '0.06513_1';
}
use Moose::Role;

# with Moose >= 2.00, this must be present also in roles
use MooseX::SemiAffordanceAccessor;
use Treex::Core::Log;
use List::Util qw(first);    # TODO: this wouldn't be needed if there was Treex::Core::Common for roles

has ord => (
    is     => 'ro',
    isa    => 'Int',         # TODO non-negative Int
    writer => '_set_ord',
    reader => 'ord',
);

sub precedes {
    log_fatal 'Incorrect number of arguments' if @_ != 2;
    my ( $self, $another_node ) = @_;
    return $self->ord() < $another_node->ord();
}

# Methods get_next_node and get_prev_node are implemented
# so they can handle deprecated fractional ords.
# When no "fract-ords" will be used in the whole TectoMT nor Treex
# this could be reimplemented a bit more effectively.
# TODO
sub get_next_node {
    log_fatal 'Incorrect number of arguments' if @_ != 1;
    my $self   = shift;
    my $my_ord = $self->ord();
    log_fatal('Undefined ordering value') if !defined $my_ord;

    # Find closest higher ord
    my ( $next_node, $next_ord ) = ( undef, undef );
    foreach my $node ( $self->get_root()->get_descendants() ) {
        my $ord = $node->ord();
        next if $ord <= $my_ord;
        next if defined $next_ord && $ord > $next_ord;
        ( $next_node, $next_ord ) = ( $node, $ord );
    }
    return $next_node;
}

sub get_prev_node {
    log_fatal 'Incorrect number of arguments' if @_ != 1;
    my $self   = shift;
    my $my_ord = $self->ord();
    log_fatal('Undefined ordering value') if !defined $my_ord;

    # Find closest lower ord
    my ( $prev_node, $prev_ord ) = ( undef, undef );
    foreach my $node ( $self->get_root()->get_descendants() ) {
        my $ord = $node->ord();
        next if $ord >= $my_ord;
        next if defined $prev_ord && $ord < $prev_ord;
        ( $prev_node, $prev_ord ) = ( $node, $ord );
    }
    return $prev_node;
}

sub _normalize_node_ordering {
    log_fatal 'Incorrect number of arguments' if @_ != 1;
    my $self = shift;
    log_fatal('Ordering normalization can be applied only on root nodes!') if $self->get_parent();
    my $new_ord = 0;
    foreach my $node ( $self->get_descendants( { ordered => 1, add_self => 1 } ) ) {
        $node->_set_ord($new_ord);
        $new_ord++
    }
    return;
}

sub _check_shifting_method_args {
    my ( $self, $reference_node, $arg_ref ) = @_;
    my @c     = caller 1;
    my $stack = "$c[3] called from $c[1], line $c[2]";
    log_fatal( 'Incorrect number of arguments for ' . $stack ) if @_ < 2 || @_ > 3;
    log_fatal( 'Undefined reference node for ' . $stack ) if !$reference_node;
    log_fatal( 'Reference node must be from the same tree. In ' . $stack )
        if $reference_node->get_root() != $self->get_root();

    log_fatal '$reference_node is a descendant of $self.'
        . ' Maybe you have forgotten {without_children=>1}. ' . "\n" . $stack
        if !$arg_ref->{without_children} && $reference_node->is_descendant_of($self);

    return if !defined $arg_ref;

    log_fatal(
        'Second argument for shifting methods can be only options hash reference. In ' . $stack
    ) if ref $arg_ref ne 'HASH';
    my $unknown = first { $_ ne 'without_children' } keys %{$arg_ref};
    log_warn("Unknown switch '$unknown' for $stack") if defined $unknown;
    return;
}

sub shift_after_node {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return if $self == $reference_node;
    _check_shifting_method_args(@_);
    return $self->_shift_to_node( $reference_node, 1, $arg_ref->{without_children} ) if $arg_ref;
    return $self->_shift_to_node( $reference_node, 1, 0 );
}

sub shift_before_node {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return if $self == $reference_node;
    _check_shifting_method_args(@_);
    return $self->_shift_to_node( $reference_node, 0, $arg_ref->{without_children} ) if $arg_ref;
    return $self->_shift_to_node( $reference_node, 0, 0 );
}

sub shift_after_subtree {
    my ( $self, $reference_node, $arg_ref ) = @_;
    _check_shifting_method_args(@_);

    my $last_node = $reference_node->get_descendants( { except => $self, last_only => 1, add_self => 1 } );
    return $self->_shift_to_node( $last_node, 1, $arg_ref->{without_children} ) if $arg_ref;
    return $self->_shift_to_node( $last_node, 1, 0 );
}

sub shift_before_subtree {
    my ( $self, $reference_node, $arg_ref ) = @_;
    _check_shifting_method_args(@_);

    my $first_node = $reference_node->get_descendants( { except => $self, first_only => 1, add_self => 1 } );
    return $self->_shift_to_node( $first_node, 0, $arg_ref->{without_children} ) if $arg_ref;
    return $self->_shift_to_node( $first_node, 0, 0 );
}

# This method does the real work for all shift_* methods.
# However, due to unfriendly name and arguments it's not public.
sub _shift_to_node {
    my ( $self, $reference_node, $after, $without_children ) = @_;
    my @all_nodes = $self->get_root()->get_descendants();

    # Make sure that ord of all nodes is defined
    #my $maximal_ord = @all_nodes; -this does not work, since there may be gaps in ordering
    my $maximal_ord = 10000;
    foreach my $d (@all_nodes) {
        if ( !defined $d->ord() ) {
            $d->_set_ord( $maximal_ord++ );
        }
    }

    # Which nodes are to be moved?
    # $self only (the {without_children=>1} switch)
    # or $self and all its descendants (the default)?
    my @nodes_to_move;
    if ($without_children) {
        @nodes_to_move = ($self);
    }
    else {
        @nodes_to_move = $self->get_descendants( { ordered => 1, add_self => 1 } );
    }

    # Let's make a hash, so we can easily recognize which nodes are to be moved.
    my %is_moving = map { $_ => 1 } @nodes_to_move;

    # Recompute ord of all nodes.
    # The technical root has ord=0 and the first node will have ord=1.
    my $counter = 1;
    @all_nodes = sort { $a->ord() <=> $b->ord() } @all_nodes;
    foreach my $node (@all_nodes) {

        # We skip nodes that are being moved.
        # Their ord is recomuted elsewhere (look 8 lines down).
        next if $is_moving{$node};

        # If moving "after" a reference node
        # then ord of the $node can be recomputed now
        # even if it is actually the $reference_node.
        if ($after) {
            $node->_set_ord( $counter++ );
        }

        # Now we insert (i.e. recompute ord of) all nodes which are being moved.
        # The nodes are inserted in the original order.
        if ( $node == $reference_node ) {
            foreach my $moving_node (@nodes_to_move) {
                $moving_node->_set_ord( $counter++ );
            }
        }

        # If moving "before" a node, then now it is the right moment
        # for recomputing ord of the $node
        if ( !$after ) {
            $node->_set_ord( $counter++ );
        }
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Core::Node::Ordered

=head1 VERSION

version 0.06513_1

=head1 DESCRIPTION

Moose role for nodes which can/should be ordered by the attribute C<ord>
(usually following the word order).

=head1 ATTRIBUTES

=over

=item ord

The ordering attribute, ordinal number of a node.
The ordering should be without gaps, so

    print join ' ', map {$_->ord} $root->get_descendants({ordered=>1});
    # should print
    # 1 2 3 ... number_of_descendants

=back

=head1 METHODS

=head2 Access to nodes ordering

=over

=item my $boolean = $node->precedes($another_node);

Does this node precede C<$another_node>?

=item my $following_node = $node->get_next_node();

Return the closest following node (according to the ordering attribute)
or C<undef> if C<$node> is the last one in the tree.

=item my $preceding_node = $node->get_prev_node();

Return the closest preceding node (according to the ordering attribute)
or C<undef> if C<$node> is the first one in the tree.

=back

=head2 Reordering nodes

Next four methods for changing the order of nodes
(the word order defined by the attribute C<ord>)
have an optional argument C<$arg_ref> for specifying switches.
So far there is only one switch - C<without_children>
which is by default set to 0.
It means that the default behavior is to shift the node
with all its descendants.
Only if you want to leave the position of the descendants unchanged
and shift just the node, use e.g.

 $node->shift_after_node($reference_node, {without_children=>1});

Shifting involves only changing the ordering attribute (C<ord>) of nodes.
There is no rehanging (changing parents). The node which is
going to be shifted must be already added to the tree
and the reference node must be in the same tree.

For languages with left-to-right script: C<after> means "to the right of"
and C<before> means "to the left of".

=over

=item $node->shift_after_node($reference_node);

Shifts (changes the C<ord> of) the node just behind the reference node.

=item $node->shift_after_subtree($reference_node);

Shifts (changes the C<ord> of) the node behind the subtree of the reference node.

=item $node->shift_before_node($reference_node);

Shifts (changes the C<ord> of) the node just in front of the reference node.

=item $node->shift_before_subtree($reference_node);

Shifts (changes the C<ord> of) the node in front of the subtree of the reference node.

=back


=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.