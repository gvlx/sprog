package Sprog::Gear::CSVSplit;

=begin sprog-gear-metadata

  title: CSV Split
  type_in: P
  type_out: A
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);


my $field = qr/
  (?:
      [^,"\r\n][^,\r\n]*         # an unquoted non zero length string
    | (")(?:""|[^"])*"[^,\r\n]*  # a quoted string with optional trailing junk
    |                            # a zero length string
  )
/x;


sub file_start {
  my $self = shift;

  $self->{_buf} = '';
  $self->{_row} = [];
}


sub data {
  my $self  = shift;

  local($_) = shift;

  CHUNK: while(1) {
    FIELD_CHECK: while(1) {
      if(s/^($field)(?=(?:,|\n))//os) {
        push @{$self->{_row}}, $1;
        if($2 and $2 eq '"') {
          $self->{_row}->[-1] =~ s/^"((?:""|[^"])*)"/$1/; # strip outer quotes
          $self->{_row}->[-1] =~ s/""/"/g;                # unescape inner ones
        }
        s/\A,// && next FIELD_CHECK;
      }
      else {
        last FIELD_CHECK;
      }
      if(/\A\n/) {                                    # at the end of the line?
        $self->_send_row;
        s/\A\n//s;
        next FIELD_CHECK;
      }
    }

    my $queue = $self->msg_queue;
    if(@$queue) {
      if($queue->[0]->[0] eq 'data') {
        my $msg = shift @$queue;
        $_ .= $msg->[1];
        redo CHUNK;
      }
      else {  # a non 'data' message follows
        $self->_send_row($_) if length $_;
        return;
      }
    }
    else {
      $self->requeue_message_delayed(data => $_) if length $_;
    }
    last CHUNK;
  };

}


sub _send_row {
  my $self = shift;

  my $row = delete $self->{_row};
  push @$row, shift if @_;
  $self->msg_out(row => $row) if @$row;

  $self->{_row} = [];
}


sub file_end {
  my $self = shift;

  $self->_send_row;
}

1;

__END__


=head1 NAME

Sprog::Gear::CSVSplit - Parse CSV data into rows of field values

=head1 DESCRIPTION

This gear parses data from a CSV (comma-separated value) format into rows of
field values.  Fields enclosed in double quotes may include commas, newlines
and double quotes.  Each embedded double quote character must be preceded by
another double quote 'escape' character.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 CSV Split Gear

This gear reads text data in comma-separated value (CSV) format from the 'pipe'
input connector and sends rows of field values out the 'list' output connector.

The particular dialect of CSV recognised by this gear uses double quotes around
fields that contain commas, newlines or double quotes.  Within a quoted field,
each double quote character must be preceded by another double quote character.

=head2 Properties

This gear has no properties.

=end :sprog-help-text

