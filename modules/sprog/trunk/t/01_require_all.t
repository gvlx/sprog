use strict;
use warnings;

my @libs;

BEGIN {
  open my $manifest, '<', 'MANIFEST' or die "Error reading MANIFEST: $!\n";

  @libs = map { s{/}{::}g; $_ } map { m{^lib/(.*).pm} ? $1 : () } <$manifest>;

  use Sprog::TestHelper tests => scalar(@libs), display => 1;
}

require_ok($_) foreach (@libs);
