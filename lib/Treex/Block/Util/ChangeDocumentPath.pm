package Treex::Block::Util::ChangeDocumentPath;
BEGIN {
  $Treex::Block::Util::ChangeDocumentPath::VERSION = '0.08083';
}
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

has [qw(file_stem path)] => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'sets the respective attribute',
);

has pathre => (
    is            => 'ro',
    isa           => 'Str',
    documentation => 'The regular expression to apply on document path, e.g. /foo/bar/',
);


sub process_document {
    my ( $self, $document ) = @_;

    if (defined $self->pathre) {
        my $p = $document->path;
        my $pathre = $self->pathre;
        eval "\$p =~ s$pathre;";
        $document->set_path($p);
    }

    $document->set_path($self->path) if defined $self->path;
    $document->set_file_stem($self->file_stem) if defined $self->file_stem;

    return 1;
}

1;

__END__

=head1 NAME

Treex::Block::Util::ChangeDocumentPath

=head1 VERSION

version 0.08083

=head1 DESCRIPTION

Modifies the document meta-information on filename. Useful before various
Writers.

  Util::ChangeDocumentPath pathre=/foo/bar/

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.