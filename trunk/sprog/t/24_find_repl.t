use strict;
use Sprog::TestHelper tests => 30;

my $data_file = File::Spec->catfile('t', 'files.txt');
open my $fh, '<', $data_file or die "open($data_file): $!";
my @all = <$fh>;
close $fh;

use_ok('TestApp');

my $app = TestApp->make_test_app;

my($reader, $subst, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::ReadFile
  Sprog::Gear::FindReplace
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');


isa_ok($subst, 'Sprog::Gear::FindReplace', 'find/replace gear');
isa_ok($subst, 'Sprog::Gear::InputByLine', 'find/replace gear');
isa_ok($subst, 'Sprog::Gear',              'find/replace gear');

ok($subst->has_input, 'has input');
ok($subst->has_output, 'has output');
is($subst->title, 'Find and Replace', 'title looks ok');
like($subst->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
ok($subst->ignore_case, 'case-insensitive matching defaults on');
ok($subst->global_replace, 'global replacement defaults on');
is($subst->pattern, '', 'default pattern is blank');
is($subst->replacement, '', 'default replacement is blank');


isa_ok($subst->last, 'LineSink', 'output gear');

$reader->filename($data_file);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'all lines passed through by default');


$subst->pattern(undef);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'all lines passed through by default 2');


$subst->pattern('etc');
$subst->replacement('ETC');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/ETC/hosts\n",
  "/ETC/syslog.conf\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/login\n",
  "/usr/bin/ls\n",
  "/var/log/syslog\n",
  "/var/lib/ETChingsLogo\n",
], "matched using default case-insensitive matching");


$subst->ignore_case(0);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/ETC/hosts\n",
  "/ETC/syslog.conf\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/login\n",
  "/usr/bin/ls\n",
  "/var/log/syslog\n",
  "/var/lib/EtchingsLogo\n",
], "case-sensitive matching works too");


$subst->ignore_case(1);
$subst->pattern('log');
$subst->replacement('TRUNK');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/sysTRUNK.conf\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/TRUNKin\n",
  "/usr/bin/ls\n",
  "/var/TRUNK/sysTRUNK\n",
  "/var/lib/EtchingsTRUNKo\n",
], "global replacement works");


$subst->global_replace(0);
$subst->pattern('log');
$subst->replacement('TRUNK');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/sysTRUNK.conf\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/TRUNKin\n",
  "/usr/bin/ls\n",
  "/var/TRUNK/syslog\n",
  "/var/lib/EtchingsTRUNKo\n",
], "disabling global replacement works too");


$subst->pattern('log(');
$subst->replacement('TRUNK');
like($app->test_run_machine, qr{^Error setting up find/replace\s*Unmatched}s,
  "correct alert generated when error in pattern");


$subst->pattern('log');
$subst->replacement('$bogus');
like($app->test_run_machine, qr{^Error setting up find/replace.*bogus}s,
  "correct alert generated when error in pattern");


$subst->global_replace(1);
$subst->pattern('/bin/(.*)');
$subst->replacement('/\U$1\E');
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
  "/usr/CAT\n",
  "/usr/GREP\n",
  "/usr/LOGIN\n",
  "/usr/LS\n",
  "/var/log/syslog\n",
  "/var/lib/EtchingsLogo\n",
], "slashes get escaped and captures work too");
