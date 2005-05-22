use strict;
use warnings;

use Test::More tests => 13;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_test_app;

isa_ok($app, 'TestApp', 'test app object');

my($source, $sink) = $app->make_test_machine(qw(
  MessageSource
  LineGear
));

isa_ok($sink, 'LineGear');
isa_ok($sink, 'Sprog::Gear::InputByLine');
isa_ok($sink, 'Sprog::Gear');

$source->messages(
  [ data => '' ],
);

is($app->test_run_machine, '', 'run completed without timeout or alerts');

is_deeply([ $sink->lines ], [ ], "no data yet (as expected)");


$source->messages(
  [ data => "Line one\nLine two\n" ],
);

is($app->test_run_machine, '', 'run completed without timeout or alerts');

is_deeply([ $sink->lines ], [
  "Line one\n",
  "Line two\n",
], "got the expected lines of data");


$source->messages(
  [ data => "Line three\nLine f" ],
  [ data => "our\n" ],
);

is($app->test_run_machine, '', 'run completed without timeout or alerts');

is_deeply([ $sink->lines ], [
  "Line three\n",
  "Line four\n",
], "got the expected lines of data");

$source->messages(
  [ data => "Line three\nLine f" ],
  [ data => "our\nLine five" ],
  [ data => "\nLine six\n\n0" ],
  [ data => "\n1\nTHE END!" ],
  [ file_end => "filename.txt" ],
);

is($app->test_run_machine, '', 'run completed without timeout or alerts');

is_deeply([ $sink->lines ], [
  "Line three\n",
  "Line four\n",
  "Line five\n",
  "Line six\n",
  "\n",
  "0\n",
  "1\n",
  "THE END!"
], "got the expected lines of data");

