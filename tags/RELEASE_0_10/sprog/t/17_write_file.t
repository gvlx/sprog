use strict;
use Sprog::TestHelper tests => 28;

use_ok('TestApp');
use_ok('Sprog::Gear::WriteFile');
use_ok('Sprog::Gear::TextInput');

my $app = TestApp->make_test_app;

my($input, $writer) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::WriteFile
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($writer, 'Sprog::Gear::WriteFile',  'writer gear');
isa_ok($writer, 'Sprog::Gear::OutputToFH', 'writer gear also');
isa_ok($writer, 'Sprog::Gear',             'writer gear also');

ok($writer->has_input, 'has input');
ok(!$writer->has_output, 'has no output');
is($writer->title, 'Write File', 'title looks ok');
like($writer->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');

my $output_file = File::Spec->catfile('t', 'output.txt');
unlink($output_file);

ok(!-e $output_file, 'output file does not exist before the test');

my $data = "The quick brown fox jumps over the lazy dog\n";

$input->text($data);
like($app->test_run_machine, qr/you must select an output file/i, 
  'got expected alert when no filename selected');

$writer->filename($output_file);
$input->text($data);
is($app->test_run_machine, '', 'run completed without timeout or alerts');

ok(-e $output_file, 'output file was created');

my $result = read_file($output_file);
is($result, $data, 'file contents look good');

my $prompt = '';
$app->confirm_yes_no_handler(sub { $prompt = shift; return 0 });

$input->text("Test output two\n");
is($app->test_run_machine, '', 'run completed without timeout or alerts');

like($prompt, qr/overwrite\s+$output_file/i, 'got confirm overwrite prompt');
$result = read_file($output_file);
is($result, $data, 'file was not overwritten');

$prompt = '';
$app->confirm_yes_no_handler(sub { $prompt = shift; return 1 });

$input->text("Test output three\n");
is($app->test_run_machine, '', 'run completed without timeout or alerts');

like($prompt, qr/overwrite\s+$output_file/i, 'got confirm overwrite prompt');
$result = read_file($output_file);
is($result, "Test output three\n", 'file was overwritten');


$prompt = '';
$app->confirm_yes_no_handler(sub { $prompt = shift; return 0 });

$writer->if_exists('overwrite');
$input->text("Test output four\n");
is($app->test_run_machine, '', 'run completed without timeout or alerts');

is($prompt, '', 'not prompted to confirm overwrite');
$result = read_file($output_file);
is($result, "Test output four\n", 'file was overwritten');


$prompt = '';
$writer->if_exists('append');
$input->text("Test output five\n");
is($app->test_run_machine, '', 'run completed without timeout or alerts');

is($prompt, '', 'not prompted to confirm overwrite');
$result = read_file($output_file);
is($result, "Test output four\nTest output five\n", 'file was appended');

unlink($output_file);


exit;

sub read_file {
  my($filename) = @_;

  my $data = eval {
    open my $fh, '<', $filename or die "open: $!";
    local($/) = undef;
    <$fh>;
  };
  $@ = '';
  
  return $data;
}
