use strict;
use Sprog::TestHelper tests => 17;

use_ok('DummyGear');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'           => 'TestApp',
  '/app/view'      => 'DummyView',
  '/app/eventloop' => 'Sprog::GlibEventLoop',
);
isa_ok($app, 'TestApp', 'test app object');


my $gear = DummyGear->new(x => 10, y => 20, id => 3, app => $app);
isa_ok($gear, 'DummyGear');
isa_ok($gear, 'Sprog::Gear');
ok($gear->has_input, 'has input');
ok($gear->has_output, 'has output');
ok(!$gear->no_properties, 'no_properties defaults off');
is($gear->input_type, 'P', "input connector is type 'P'");
is($gear->output_type, 'P', "output connector is type 'P'");
is($gear->title, 'Dummy Gear', 'title set from metadata');
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

