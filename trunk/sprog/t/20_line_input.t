use strict;
use warnings;

use Test::More tests => 14;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('LineGear');

my $gear = LineGear->new;

isa_ok($gear, 'LineGear');
isa_ok($gear, 'Sprog::Gear::InputByLine');
isa_ok($gear, 'Sprog::Gear');

$gear->prime;    # Create the incoming message queue

$gear->msg_in(data => '');

$gear->turn_once;

is_deeply([ $gear->lines ], [ ], "no data yet (as expected)");


$gear->msg_in(data => "Line one\nLine two\n");

$gear->turn_once;

is_deeply([ $gear->lines ], [
  "Line one\n",
  "Line two\n",
], "got the expected lines of data");


$gear->msg_in(data => "Line three\nLine f");

$gear->turn_once;

is_deeply([ $gear->lines ], [
  "Line one\n",
  "Line two\n",
  "Line three\n",
], "got the expected lines of data");


$gear->msg_in(data => "our\nLine five");

$gear->turn_once;

is_deeply([ $gear->lines ], [
  "Line one\n",
  "Line two\n",
  "Line three\n",
  "Line four\n",
], "got the expected lines of data");


$gear->msg_in(data => "\nLine six\n\n0");
$gear->msg_in(data => "\n1\nTHE END!");
$gear->msg_in(file_end => "filename.txt");

$gear->turn_once;

is_deeply([ $gear->lines ], [
  "Line one\n",
  "Line two\n",
  "Line three\n",
  "Line four\n",
  "Line five\n",
  "Line six\n",
  "\n",
  "0\n",
  "1\n",
  "THE END!"
], "got the expected lines of data");


# Now try a gear without a 'line' method

use_ok('DummyGear');

$gear = DummyGear->new;

isa_ok($gear, 'DummyGear');
isa_ok($gear, 'Sprog::Gear::InputByLine');
isa_ok($gear, 'Sprog::Gear');

$gear->prime;    # Create the incoming message queue

$gear->msg_in(data => "Line one\nLine two\n");

$@ = '';
eval {
  $gear->turn_once;
};
like("$@", qr/Gear has no 'line' method/,
  "correct failure mode if 'line' method not implemented");

