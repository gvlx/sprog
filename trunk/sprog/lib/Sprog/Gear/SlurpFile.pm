package Sprog::Gear::SlurpFile;

sub file_start {
  my($self, $filename) = @_;

  $self->{_data} = [];

  $self->msg_out(file_start => $filename);
}


sub data {
  my($self, $data) = @_;

  push @{$self->{_data}}, $data;
}


sub file_end {
  my($self, $filename) = @_;
  
  my $data = delete $self->{_data} || [];

  $self->file_data(join('', @$data), $filename);

  $self->msg_out(file_end => $filename);
}

1; 


=head1 NAME

Sprog::Gear::SlurpFile - a 'mixin' class for gears reading a file at a time

=head1 SYNOPSIS

  use base qw(
    Sprog::Gear::SlurpFile
    Sprog::Gear
  );

=head1 DESCRIPTION

This mixin is for use by gears which use a 'pipe' style of input connector but
only want to process a whole file at a time.  It defines a C<data> method which
buffers input until the C<file_end> event, at which point the C<file_data>
method is called and passed all the accumulated data.

=head1 METHODS

=head2 file_start ( filename )

Resets the buffer and then propagates the C<file_start> event.

=head2 data ( chunk )

Adds the chunk of input into a buffer.

=head2 file_end ( filename )

Passes the accumulated data from the buffer to the C<file_data> method and then
propagates the C<file_start> event.

A class that uses this mixin is expected to implement a C<file_data> method. 
It should accept two arguments: the data and the filename.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


