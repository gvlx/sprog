use strict;
use Sprog::TestHelper tests => 26;

use_ok('TextSink');
use_ok('Sprog::Gear::ReadFile');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'           => 'DummyApp',
  '/app/machine'   => 'DummyMachine',
  '/app/eventloop' => 'Sprog::GlibEventLoop',
);

isa_ok($app, 'DummyApp');

my $machine = $app->machine;
isa_ok($machine, 'DummyMachine');

my $sink = TextSink->new(machine => $machine, app => $app);
isa_ok($sink, 'TextSink');
$sink->text('');

my $reader = Sprog::Gear::ReadFile->new(app => $app, machine => $machine);

isa_ok($reader, 'Sprog::Gear::ReadFile');
isa_ok($reader, 'Sprog::Gear::InputFromFH');
isa_ok($reader, 'Sprog::Gear');
ok(!$reader->has_input, 'has no input');
ok($reader->has_output, 'has output');
is($reader->output_type, 'P', 'correct input connector type (pipe)');
is($reader->title, 'Read File', 'title looks good');
like($reader->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');

$reader->next($sink);


$reader->filename(undef);

$reader->engage;

like($app->alerts, qr/You must select an input file/,
  "correct alert generated when filename undefined");
$app->alerts('');


$reader->filename('');

$reader->engage;

like($app->alerts, qr/You must select an input file/,
  "correct alert generated when filename blank");
$app->alerts('');


$reader->filename(File::Spec->catfile('t', 'bogus.txt'));

$reader->engage;

like($app->alerts, qr/Can't open ".*?bogus.txt"/,
  "correct alert generated when file does not exist");


$app->alerts('');

$reader->filename(File::Spec->catfile('t', 'rgb.txt'));

$sink->engage;
$reader->engage;

is($app->alerts, '', "successfully opened named file");

$reader->send_data;

my $io_queue = $app->io_readers || [];

is(scalar(@$io_queue), 1, "one io_reader message queued");

$reader->send_data;

is(scalar(@$io_queue), 1, "still only one io_reader message queued");

my $sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();

$reader->send_data;    # Go for the EOF event

is(scalar(@$io_queue), 1, "one new io_reader message queued");

$sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();



$reader = undef;
$app    = undef;

use_ok('TestApp');

$app = TestApp->make_test_app;

($reader, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::ReadFile
  LineSink
));
is($app->alerts, '', 'created a machine with a ReadFile gear');

$reader->filename(File::Spec->catfile('t', 'rgb.txt'));

is($app->test_run_machine, '', 'running machine produced no alerts');

is_deeply([ $sink->lines ], [
    "#FF0000 Red\n",
    "#00FF00 Green\n",
    "#0000FF Blue\n",
    "#FFFF00 Yellow\n",
    "#00FFFF Cyan\n",
    "#FF00FF Purple\n",
  ],
  "successfully read contents of file");
