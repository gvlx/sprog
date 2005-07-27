use strict;
use Sprog::TestHelper tests => 15, requires => [ 'LWP', '{local_apache}' ];

use_ok('TestApp');
use_ok('Sprog::Gear::RetrieveURL');

my $app = TestApp->make_test_app;

my($source, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::RetrieveURL
  TextSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($source, 'Sprog::Gear::RetrieveURL', 'filter gear');
isa_ok($source, 'Sprog::Gear::CommandIn',   'filter gear also');
isa_ok($source, 'Sprog::Gear',              'filter gear also');

ok(!$source->has_input, 'has no input');
ok($source->has_output, 'has output');
is($source->output_type, 'P', 'correct output connector type (pipe)');
is($source->title, 'Retrieve URL', 'title looks ok');
like($source->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($source->url, '', "default URL is blank");

my $props = $source->serialise->{prop};
delete $props->{title};
is_deeply($props, { url => '' }, 'command property was uninherited OK');

$source->url('http://localhost/sprogtest/index.html');

is($app->test_run_machine, '', 'ran machine without error');

like($sink->text, qr{<html>.*Test Document.*</html>}s, 
  'content retrieved successfully');


