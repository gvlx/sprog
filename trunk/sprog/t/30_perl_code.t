use strict;
use warnings;

use Test::More tests => 27;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

my $data = <<'EOF';
/etc/hosts
/etc/syslog.conf
/usr/bin/cat
/usr/bin/grep
/usr/bin/login
/usr/bin/ls
/var/log/syslog
/var/lib/EtchingsLogo
EOF

my @all = $data =~ /(.*?\n)/g;


use_ok('TestApp');
use_ok('Sprog::Gear::PerlCode');
use_ok('LineGear');

my $app = TestApp->make_test_app;

my($input, $perl, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::PerlCode
  LineGear
));
is($app->alerts, '', 'no alerts while creating machine');


isa_ok($perl, 'Sprog::Gear::PerlCode');
isa_ok($perl, 'Sprog::Gear::InputByLine');
isa_ok($perl, 'Sprog::Gear');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

isa_ok($perl->last, 'LineGear');


$input->text($data);
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');


$perl->perl_code(undef);
$sink->reset;
is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$perl->perl_code('$_ = "*** $_"');
$perl->prime;
is($app->alerts, '', 'no problem compiling code');
$sink->reset;

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "*** /etc/hosts\n",
  "*** /etc/syslog.conf\n",
  "*** /usr/bin/cat\n",
  "*** /usr/bin/grep\n",
  "*** /usr/bin/login\n",
  "*** /usr/bin/ls\n",
  "*** /var/log/syslog\n",
  "*** /var/lib/EtchingsLogo\n",
], "matched using default case-insensitive matching");
$sink->reset;


$perl->perl_code('print uc if /log/');
$perl->prime;
is($app->alerts, '', "doesn't choke on print statement");

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/ETC/SYSLOG.CONF\n",
  "/etc/syslog.conf\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/USR/BIN/LOGIN\n",
  "/usr/bin/login\n",
  "/usr/bin/ls\n",
  "/VAR/LOG/SYSLOG\n",
  "/var/log/syslog\n",
  "/var/lib/EtchingsLogo\n",
], "print function successfully intercepted");
$sink->reset;


$perl->perl_code('
  if(m{/bin/(\w+)}) {
    print "Command: $1\n";
    print "Gotta love that grep!\n" if /grep/;
    next LINE;
  }
  print "Library - " if /lib/;
');
$perl->prime;
is($app->alerts, '', "more complex code snippet compiles OK");

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
  "Command: cat\n",
  "Command: grep\n",
  "Gotta love that grep!\n",
  "Command: login\n",
  "Command: ls\n",
  "/var/log/syslog\n",
  "Library - /var/lib/EtchingsLogo\n",
], "multiple prints and 'next' play nice");
$sink->reset;


$perl->perl_code("\nuse Bogus::NonExistant::Module");
$perl->prime;
like($app->alerts, qr/Can't locate Bogus.* at your code line 2/i, 
  'problem compiling bad code was reported correctly');
$sink->reset;
