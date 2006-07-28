use Sprog::TestHelper tests => 16;

use_ok('TestApp');
use_ok('Sprog::Gear::CommandOut');

my $app = TestApp->make_test_app;

my($src, $output, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::CommandOut
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($output, 'Sprog::Gear::CommandOut',    'output gear');
isa_ok($output, 'Sprog::Mixin::OutputToFH',   'output gear also');
isa_ok($output, 'Sprog::Gear',                'output gear also');

ok($output->has_input,   'has input');
ok(!$output->has_output, 'has no output');
is($output->input_type,  'P', 'input connector is a pipe');
is($output->title, 'Run Command', 'title looks ok');
like($output->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');

my $data = "January\nFebruary\nMarch\nApril\n";

$src->text($data);
like($app->test_run_machine, qr/you must enter a command/i, 
  'got expected alert when no command entered');

my $filename = File::Spec->catfile('t', 'output.txt');
unlink($filename);
ok(!-e $filename, 'output file does not exist initially');

$output->command( q(perl -pe 'BEGIN { open STDOUT, ">", shift }; $_ = uc;' ) . $filename);

is($app->test_run_machine, '', 'ran machine without error');

ok(-e $filename, 'output file was created');

my $DATA = do {
  local($/);
  open my $fh, '<', $filename or die $!;
  <$fh>;
};

is($DATA, uc($data), 'data was correctly transformed');
unlink($filename);

