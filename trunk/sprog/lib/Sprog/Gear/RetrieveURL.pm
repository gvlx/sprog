package Sprog::Gear::RetrieveURL;

=begin sprog-gear-metadata

  title: Retrieve URL
  type_in: _
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::CommandIn
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  url   =>  '',
);


sub engage {
  my($self) = @_;

  return $self->alert('You must enter a URL') unless $self->url;

  return $self->SUPER::engage;
}


sub command {
  my $self = shift;

  my $url = $self->url;
  return qq(perl -MLWP::Simple -e 'getprint "$url"');
}

sub dialog_xml {
  return 'file:/home/grant/projects/sf/sprog/glade/retrieveurl.glade';
  return <<'END_XML';
END_XML
}

1;


__END__

=head1 NAME

Sprog::Gear::RetrieveURL - Read a file from a web server

=head1 DESCRIPTION

This is a data input gear.  It retrieves a file identified by a URL and passes
the file contents downstream using a 'pipe' connector.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Retrieve URL Gear

The 'Retrieve URL' gear allows you to download a file from a web server and
and pass the file contents out through a 'pipe' connector.

I<Warning this is just a proof-of-concept implementation.  It will be replaced
with a more robust version with proxy support and proper error handling soon>.

=head2 Properties

The Retrieve URL gear has only one property - the URL of the file to retrieve.  Simply type or paste in the URL.

=end :sprog-help-text

