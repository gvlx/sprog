package Sprog::Gear::ImageBorder;

=begin sprog-gear-metadata

  title: Add Border to Image
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear);

use Imager;


sub file_start {
  my($self, $filename) = @_;

  $self->{_buf} = '';
  $self->msg_out(file_start => $filename);
}


sub data {
  my($self, $data) = @_;

  $self->{_buf} .= $data;
}


sub file_end {
  my($self, $filename) = @_;

  eval { $self->_add_border($filename) };
  return $self->alert("Error in image transformation", "$@") if $@;

  $self->msg_out(file_end => $filename);
}


sub _add_border {
  my($self, $filename) = @_;

  my($type) = ($filename =~ /\.(\w+)$/);
  die "Can't get image type from file suffix" unless $type;

  my $src = Imager->new();

  $src->open(data => $self->{_buf}) or die $src->errstr();

my $bw = 10;
  my $sw = $src->getwidth;
  my $sh = $src->getheight;

  my $dw = $sw + 2 * $bw;
  my $dh = $sh + 2 * $bw;

  my $dst = Imager->new(xsize => $dw, ysize => $dh, channels => 4);

  my $black = Imager::Color->new(0, 0, 0);

  $dst->box(color => $black, xmin => 0, ymin => 0, xmax => $dw, ymax => $dh, filled => 1);

  $dst->paste(left => $bw, top => $bw, img => $src);

  $dst->write(
    callback => sub { $self->msg_out(data => shift); },
    type => $type,
  ) or die $dst->errstr();
}


1;

