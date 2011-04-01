package Treex::Block::Read::Sentences;
BEGIN {
  $Treex::Block::Read::Sentences::VERSION = '0.05222';
}
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Read::BaseTextReader';

sub next_document {
    my ($self) = @_;
    my $text = $self->next_document_text();
    return if !defined $text;

    my $document = $self->new_document();
    foreach my $sentence ( split /\n/, $text ) {
        my $bundle = $document->create_bundle();
        my $zone = $bundle->create_zone( $self->language, $self->selector );
        $zone->set_sentence($sentence);
    }

    return $document;
}

1;

__END__

=head1 NAME

Treex::Block::Read::Sentences

=head1 VERSION

version 0.05222

=head1 DESCRIPTION

Document reader for plain text format, one sentence per line.

=head1 ATTRIBUTES

=over

=item from

space or comma separated list of filenames

=back

=head1 METHODS

=over

=item next_document

Loads a document.

=back

=head1 AUTHOR

Martin Popel

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.