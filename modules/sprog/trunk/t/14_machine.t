use Sprog::TestHelper tests => 26;

my $test_file = File::Spec->catfile('t', 'ffff.sprog'); # Does not exist yet


use_ok('TestApp');

my $app = TestApp->make_test_app;

isa_ok($app, 'TestApp');
isa_ok($app, 'Sprog');

my $machine = $app->machine;
isa_ok($machine, 'TestMachine');
isa_ok($machine, 'Sprog::Machine');

my($reader, $grep, $case, $text) = $app->make_test_machine(qw(
  Sprog::Gear::ReadFile
  Sprog::Gear::Grep
  Sprog::Gear::UpperCase
  TextSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($reader, 'Sprog::Gear::ReadFile');
isa_ok($grep,   'Sprog::Gear::Grep');
isa_ok($case,   'Sprog::Gear::UpperCase');
isa_ok($text,   'TextSink');

like($app->test_run_machine, qr/^You must select an input file\s+<undef>/s,
  'correct alerts generated from unconfigured ReadFile gear');

$reader->filename(File::Spec->catfile('t', 'rgb.txt'));
is($app->test_run_machine, '', 'run completed without timeout or alerts');
like($text->text, qr/
  #FF0000 \s RED     \s+
  #00FF00 \s GREEN   \s+
  #0000FF \s BLUE    \s+
  #FFFF00 \s YELLOW  \s+
  #00FFFF \s CYAN    \s+
  #FF00FF \s PURPLE  \s+
/xs, 'got the expected output');


$grep->pattern('FFFF');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
like($text->text, qr/
  #FFFF00 \s YELLOW  \s+
  #00FFFF \s CYAN    \s+
/xs, 'filtered output looks ok');


unlink($test_file);  # Remove evidence from previous bad runs

$app->file_save;
is($app->alerts, '', 'no alerts while saving');
ok(-f $test_file, "successfully wrote $test_file");

$machine->expunge;
is(scalar(values %{$machine->_parts}), 0, 'the machine was successfully expunged');
($reader, $grep, $case, $text) = ();

$app->filename(undef);
$app->load_from_file($test_file);

is(scalar(values %{$machine->_parts}), 4, 'loaded machine from file');
is($app->filename, $test_file, 'filename was remembered');
unlink($test_file);

ok(!-f $test_file, "removed file");
$app->file_save;
ok(-f $test_file, "file was re-written successfully");

($grep) = grep $_->isa('Sprog::Gear::Grep'), values %{$machine->_parts};
ok(defined($grep), 'machine contains the grep gear');

($text) = grep $_->isa('TextSink'), values %{$machine->_parts};
ok(defined($text), 'machine contains the text gear');

$grep->pattern('00FF');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
like($text->text, qr/
  #00FF00 \s GREEN   \s+
  #0000FF \s BLUE    \s+
  #00FFFF \s CYAN    \s+
  #FF00FF \s PURPLE  \s+
/xs, 'filtered output looks ok');

unlink($test_file);

exit 1;

sub DummyView::file_save_as_filename {
  die "No 'save' filename defined\n" unless $test_file;

  return $test_file;
}
