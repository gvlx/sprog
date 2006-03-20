use strict;
use warnings;

use Test::More tests => 27;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('DummyGear');
my $gear = DummyGear->new(x => 10, y => 20, id => 3);
isa_ok($gear, 'DummyGear');
isa_ok($gear, 'Sprog::Gear');
ok($gear->has_input, 'has input');
ok($gear->has_output, 'has output');
ok(!$gear->no_properties, 'no_properties defaults off');
is($gear->input_type, 'P', "input connector is type 'P'");
is($gear->output_type, 'P', "output connector is type 'P'");
is($gear->title, '', 'title defaults to blank string');
is($gear->view_subclass, '', 'no custom view subclass');
is($gear->next, undef, 'no next gear');
is($gear->id, 3, 'this gear has id: 3');
is($gear->last->id, 3, 'this gear is the last gear');

$@ = '';
eval {
  $gear->msg_out();
  $gear->msg_out('data');
  $gear->msg_out('data' => 'the quick brown fox');
};
is("$@", '', "gear silently drops bad messages and if no next");

my @defaults = $gear->defaults;
is(scalar(@defaults), 0, 'no default property key/values');

my $ref = $gear->serialise;

is_deeply($ref, {
    CLASS => 'DummyGear',
    ID    => 3,
    NEXT  => undef,
    X     => 10,
    Y     => 20,
    prop  => { },
}, 'serialised structure looks good');


use_ok('Sprog::Gear::Top');
my $top = Sprog::Gear::Top->new;
isa_ok($top, 'Sprog::Gear::Top');
isa_ok($top, 'Sprog::Gear');
ok(!defined($top->input_type), 'top gear input type undefined');
ok(!$top->has_input, 'top gear has no input');

$@ = '';
eval {
  my $queue = $top->msg_queue;
};
like("$@", qr/Sprog::Gear::Top has no input queue/, 
  'dies on attempt to access non-existant message queue');


use_ok('Sprog::Gear::Bottom');
my $bottom = Sprog::Gear::Bottom->new;
isa_ok($bottom, 'Sprog::Gear::Bottom');
isa_ok($bottom, 'Sprog::Gear');
ok(!defined($bottom->output_type), 'bottom gear output type undefined');
ok(!$bottom->has_output, 'bottom gear has no output');


