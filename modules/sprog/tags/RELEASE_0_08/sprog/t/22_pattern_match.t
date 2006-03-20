use strict;
use warnings;

use Test::More tests => 22;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}


my $data_file = File::Spec->catfile('t', 'files.txt');
open my $fh, '<', $data_file or die "open($data_file): $!";
my @all = <$fh>;
close $fh;

use_ok('TestApp');

my $app = TestApp->make_test_app;

my($reader, $grep, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::ReadFile
  Sprog::Gear::Grep
  LineGear
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($sink, 'LineGear');
isa_ok($grep, 'Sprog::Gear::Grep');

ok($grep->has_input, 'has input');
ok($grep->has_output, 'has output');
is($grep->title, 'Pattern Match', 'title looks ok');
like($grep->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
ok($grep->ignore_case, 'case-insensitive matching defaults on');
ok(!$grep->invert_match, 'inverted matching defaults off');
isa_ok($grep->last, 'LineGear');

my $ref = $grep->serialise;
is($ref->{NEXT}, $sink->id, 'successfully got next gear id for serialising');


$reader->filename($data_file);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');


$grep->pattern('');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$grep->pattern('etc');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
  "/var/lib/EtchingsLogo\n",
], "matched using default case-insensitive matching");


$grep->pattern('etc');
$grep->ignore_case(0);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
], "switched to case-sensitive match");


$grep->pattern('log');
$grep->ignore_case(1);
$grep->invert_match(1);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/ls\n",
], "back to case-insensitive but inverted matching enabled");

