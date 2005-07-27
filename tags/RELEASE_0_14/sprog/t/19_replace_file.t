use strict;
use Sprog::TestHelper tests => 22;

use_ok('TestApp');
use_ok('Sprog::Gear::ReplaceFile');

my $app = TestApp->make_test_app;

my($reader, $filter, $writer) = $app->make_test_machine(qw(
  Sprog::Gear::ReadFile
  Sprog::Gear::UpperCase
  Sprog::Gear::ReplaceFile
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($writer, 'Sprog::Gear::ReplaceFile', 'writer gear');
isa_ok($writer, 'Sprog::Mixin::OutputToFH', 'writer gear also');
isa_ok($writer, 'Sprog::Gear',              'writer gear also');

ok($writer->has_input, 'has input');
ok(!$writer->has_output, 'has no output');
is($writer->title, 'Replace File', 'title looks ok');
like($writer->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($writer->suffix, '.bak', 'default suffix is .bak');

my $filename = File::Spec->catfile('t', 'testdata.txt');
unlink($filename);
open my $fh, '>', $filename or die "open($filename): $!";
print $fh "The quick brown fox\njumps over the lazy dog\n";
close($fh);

my $text = read_file($filename);
is($text, "The quick brown fox\njumps over the lazy dog\n", 'input file ready');

$reader->filename($filename);
is($app->test_run_machine, '', 'ran machine with no alerts');

ok(-f $filename, 'output file exists');
$text = read_file($filename);
is($text, "THE QUICK BROWN FOX\nJUMPS OVER THE LAZY DOG\n", 
  'file contents have been replaced');

my $backup = File::Spec->catfile('t', 'testdata.txt.bak');
ok(-f $backup, 'backup file exists');
$text = read_file($backup);
is($text, "The quick brown fox\njumps over the lazy dog\n",
  'original contents have been preserved');

unlink $filename;
rename $backup, $filename;
$text = read_file($filename);
is($text, "The quick brown fox\njumps over the lazy dog\n", 'put original back');

$writer->suffix('');
is($app->test_run_machine, '', 'ran machine again with suffix diabled');

ok(-f $filename, 'output file exists');
$text = read_file($filename);
is($text, "THE QUICK BROWN FOX\nJUMPS OVER THE LAZY DOG\n", 
  'file contents have been replaced');

ok(!-f $backup, 'no backup file was created');
unlink $filename;

exit;


sub read_file {
  my($filename) = @_;

  open my $fh, '<', $filename or die "open($filename): $!";
  local($/);
  my $data = <$fh>;
}

