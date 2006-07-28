use Sprog::TestHelper tests => 28;

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
isa_ok($reader, 'Sprog::Mixin::InputFromFH');
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
  MessageSink
));
is($app->alerts, '', 'created a machine with a ReadFile gear');
$sink->concatenate_data(1);

my $rgb_file = File::Spec->catfile('t', 'rgb.txt');
$reader->filename($rgb_file);

is($app->test_run_machine, '', 'running machine produced no alerts');

is_deeply([ $sink->messages ], [
    [ file_start => $rgb_file ],
    [ data => "#FF0000 Red\n"
            . "#00FF00 Green\n"
            . "#0000FF Blue\n"
            . "#FFFF00 Yellow\n"
            . "#00FFFF Cyan\n"
            . "#FF00FF Purple\n" ],
    [ file_end => $rgb_file ],
  ],
  "successfully read named file");


open my $stdin,"<&STDIN" or die "error dup'ing STDIN";

open STDIN, '<', $rgb_file;

$reader->filename('-');
$sink->reset;
is($app->test_run_machine, '', 'ran machine to read from STDIN');

is_deeply([ $sink->messages ], [
    [ file_start => undef ],
    [ data => "#FF0000 Red\n"
            . "#00FF00 Green\n"
            . "#0000FF Blue\n"
            . "#FFFF00 Yellow\n"
            . "#00FFFF Cyan\n"
            . "#FF00FF Purple\n" ],
    [ file_end => undef ],
  ],
  "successfully read contents of file");

