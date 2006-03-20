use strict;
use Sprog::TestHelper tests => 2, display => 1;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

$app->run_sequence(
  # just use the default 'quit' action
);
