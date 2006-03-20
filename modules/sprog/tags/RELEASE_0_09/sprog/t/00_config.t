use strict;

use Test::More tests => 1;


# Build up a list of installed modules

my @mod_list = qw(
  Sprog
  Glib
  Gtk2
  Gnome2::Canvas
  Gtk2::GladeXML
  Class::Accessor
  YAML
  MIME::Base64
  LWP
  Template
  Apache::LogRegex
  XML::LibXML
);


# Extract the version number from each module

my(%version);
foreach my $module (@mod_list) {
  eval " require $module; ";
  unless($@) {
    no strict 'refs';
    $version{$module} = $module->VERSION || "Unknown";
  }
}


# Add version number of the Perl binary

eval ' use Config; $version{perl} = $Config{version} ';  # Should never fail
if($@) {
  $version{perl} = $];
}
unshift @mod_list, 'perl';


# Print details of installed modules on STDERR

diag(sprintf("\r# %-30s %s\n", 'Package', 'Version'));
foreach my $module (@mod_list) {
  $version{$module} = 'Not Installed' unless(defined($version{$module}));
  diag(sprintf(" %-30s %s\n", $module, $version{$module}));
}

# Housekeeping

ok(1, "Dumped config");
