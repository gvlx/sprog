package Sprog::GearMetadata;

use strict;

use File::Spec ();
use YAML       ();


# Package globals

my $private_path = undef;   # where user's private gears are stored
my $geardb       = {};      # metadata cache
my $scanned      = 0;       # flag to prevent re-scanning

my %_connector_sort_key = (
  '_' => 1,
  'P' => 2,
  'A' => 3,
  'H' => 4,
);


# Accessor methods - all read-only

sub class               { return shift->{class};               }
sub file                { return shift->{file};                }
sub title               { return shift->{title};               }
sub type_in             { return shift->{type_in};             }
sub type_out            { return shift->{type_out};            }
sub keywords            { return shift->{keywords};            }
sub no_properties       { return shift->{no_properties};       }
sub view_subclass       { return shift->{view_subclass};       }
sub custom_command_gear { return shift->{custom_command_gear}; }


# Public class methods

sub connector_types {
  return (
    'Any'    => '*',
    'None'   => '_',
    'Pipe'   => 'P',
    'List'   => 'A',
    'Record' => 'H',
  );
}


sub set_private_path {
  my($class, $new_path) = @_;

  $geardb       = {};
  $scanned      = 0;
  $private_path = $new_path;
}


sub gear_class_info {
  my($class, $gear_class) = @_;

  return unless $gear_class;
  return $geardb->{$gear_class} if exists $geardb->{$gear_class};

  return $class->_get_gear_attributes($gear_class);
}


sub search {
  my $class    = shift;
  my $type_in  = shift || '*';
  my $type_out = shift || '*';
  my $keyword  = shift;

  $keyword = '' unless defined($keyword);
  $keyword = lc($keyword);
  $keyword =~ s/\s+/ /sg;
  $keyword =~ s/^\s+//sg;
  $keyword =~ s/\s+$//sg;

  $class->_find_all_classes unless $scanned;

  my @matches;
  foreach (values %$geardb) {
    next if($type_in  ne '*' and $_->{type_in}  ne $type_in );
    next if($type_out ne '*' and $_->{type_out} ne $type_out);
    next if(length $keyword  and index($_->{keywords}, $keyword) < 0);

    push @matches, [ _sort_key($keyword, $_), $_ ];
  }
  return map { $_->[1] } sort { $a->[0] cmp $b->[0] } @matches;
}


# Private class methods

sub _get_gear_attributes {
  my($class, $gear_class) = @_;

  my @parts = split /::/, $gear_class;
  $parts[-1] .= '.pm';

  # Look in private gear folder first

  if($private_path) {
    my $path = File::Spec->catfile($private_path, $parts[-1]);
    return $class->_extract_metadata($path) if -r $path;
  }

  # Then search through @INC

  foreach my $dir (@INC) {
    my $path = File::Spec->catfile($dir, @parts);
    return $class->_extract_metadata($path) if -r $path;
  }

  return;  # didn't find a matching file
}


sub _extract_metadata {
  my($class, $file) = @_;

  open my $fh, '<', $file or die "open($file): $!";

  my $package = '';
  my $line    = 0;
  my $in_meta = 0;
  my $text    = '';
  while(<$fh>) {
    return if ++$line > 100;
    if(!$in_meta) {
      if(/^\s*package\s+([\w:]+)/) {
        $package = $1;
        return $geardb->{$package} if($geardb->{$package});
        next;
      }
      next unless /^=begin sprog-gear-metadata/;
      $in_meta = 1;
    }
    else {
      last if(/^=(cut|end)\b/);
      $text .= $_;
    }
  }
  return unless $text =~ /\S/;

  my $info = YAML::Load($text);
  $info->{class} = $package;
  $info->{file}  = $file;
  $info->{keywords} = '' unless defined $info->{keywords};
  $info->{keywords} = lc "$info->{title} $info->{keywords}";
  $info->{keywords} =~ s/\s+/ /sg;

  $geardb->{$package} = bless $info, $class;
}


sub _sort_key {
  my($keyword, $g) = @_;

  my $rank = 9;                  # smaller number is better (for easy sorting)
  if(length $keyword) {
    $rank -= 2 if index(lc($g->{title}),    $keyword) > -1;
    $rank -= 1 if index(lc($g->{keywords}), $keyword) > -1;
  }
  return sprintf(
    "%d%d%d%d %s",
    ($g->{type_in} eq '_' ? 1 : ($g->{type_out} eq '_' ? 3 : 2)),
    $_connector_sort_key{$g->{type_in}},
    $_connector_sort_key{$g->{type_out}},
    $rank,
    lc("$g->{title} $g->{class}"),
  );
}


sub _find_all_classes {
  my($class) = @_;

  my @gear_dirs = grep(-d, map {
    (
      File::Spec->catdir($_, 'Sprog',   'Gear'),
      File::Spec->catdir($_, 'SprogEx', 'Gear'),
    )
  } @INC);
  unshift @gear_dirs, $private_path if $private_path;

  foreach my $dir (@gear_dirs) {
    opendir my $d, $dir or next;
    foreach (grep /\.pm$/, readdir($d)) {
      $class->_extract_metadata(File::Spec->catfile($dir, $_));
    }
  }

  $scanned = 1;
}

1;

__END__

=head1 NAME

Sprog::GearMetaData - Information about installed Sprog::Gear classes

=head1 DESCRIPTION

This class is responsible for auto-discovering installed gear classes and
determining their attributes.

Querying the attributes of a class does not cause the class file to be
compiled.  Instead, each gear class is expected to start with a special
metadata POD section, like this:

  package Sprog::Gear::Grep;

  =begin sprog-gear-metadata

    title: Pattern Match
    type_in: P
    type_out: P
    keywords: grep regex regular expression search

  =end sprog-gear-metadata

  =cut

A cache of metadata is maintained so that each gear class file only needs to be
parsed once.

=head1 GEAR ATTRIBUTES

The following attributes can be defined in the metadata section:

=over 4

=item title

Mandatory - defines the text which will appear on the gear.

=item type_in

Mandatory - the input connector type.  One of:

  _ - no connector
  P - a 'Pipe' connector
  A - a 'List' connector
  H - a 'Record' connector

=item type_out

Mandatory - the output connector type.  (Same values as above).

=item keywords

An optional list of keywords that describe the gears function.  Used by the 
palette search function.

=item no_properties

An optional boolean which should be set to true (1) if the gear has no
properties dialog.  This will cause the properties option to be greyed out on
the gear's right-click menu.

=item view_subclass

An optional attribute for defining a view (user interface) class for the gear.
Rather than defining the whole class name, only the final component is
required.  For example, the L<Sprog::Gear::TextWindow> gear sets this value to
'TextWindow' which gets translated to L<Sprog::GtkGearView::TextWindow>.

=item custom_command_gear

This flag should be true for a gear created via the 'Make Command Gear' dialog
and false otherwise.

=back

=head1 CLASS METHODS

=head2 gear_class_info( class_name )

Given a full class name (eg: C<Sprog::Gear::ReadFile>), this method returns
a metadata object describing the class.  Returns undef if the class does not
exist or does not define the required metadata POD section.

=head2 search( input_connector_type, output_connector_type, keywords )

Returns a list of all classes matching the supplied arguments (all of which are
optional).  If no arguments are supplied, a list of all known gear classes will
be returned.

The input and output connector type arguments should each be a single character
as follows:

  * - accept any connector type (this is the default)
  _ - no connector at all (ie: input or output gears)
  P - a 'Pipe' connector
  A - a 'List' connector
  H - a 'Record' connector

The 'keywords' argument (if supplied) should be a string which will be used for
a case-insensitive match against each gear's title and keywords attributes.

The list of gears returned will be those that match all three arguments (or
as many as were supplied).

=head2 connector_types

This method returns a list of connector type names and the corresponding codes.
It is intended to be used to build GUI widgets for selecting input and output
connector types.


=head1 OBJECT METHODS

Each metadata object returned from C<gear_class_info()> or C<search()> will
have the following (read-only) properties:

=head2 class

The class name for the gear (eg: C<Sprog::Gear::ReadFile>).

=head2 file

The pathname of the file which defines the class.

=head2 title

The human-readable name of the gear.

=head2 type_in

The type of the input connector ('_', 'P', 'A' or 'H').

=head2 type_out

The type of the output connector (same values as for C<type_in>).

=head2 keywords

A space separated string of keywords describing the gear.

=head2 view_subclass

The gear view subclass which implements the gear's user interface.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


