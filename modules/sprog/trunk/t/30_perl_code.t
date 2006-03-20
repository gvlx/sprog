use strict;
use Sprog::TestHelper tests => 24;

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
use_ok('LineSink');

my $app = TestApp->make_test_app;

my($input, $perl, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::PerlCode
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');


isa_ok($perl, 'Sprog::Gear::PerlCode');
isa_ok($perl, 'Sprog::Mixin::InputByLine');
isa_ok($perl, 'Sprog::Gear');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

isa_ok($perl->last, 'LineSink');


$input->text($data);
is($app->test_run_machine, '', 'ran successfully with no code');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');


$perl->perl_code(undef);
is($app->test_run_machine, '', 'same again but with code = undef');
is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$perl->perl_code('$_ = "*** $_"');
is($app->test_run_machine, '', 'successfully operated on $_');
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


$perl->perl_code('print uc if /log/');
is($app->test_run_machine, '', 'ran ok with a print');
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


$perl->perl_code('
  if(m{/bin/(\w+)}) {
    print "Command: $1\n";
    print "Gotta love that grep!\n" if /grep/;
    next LINE;
  }
  print "Library - " if /lib/;
');
is($app->test_run_machine, '', 'ran ok with multiple prints');
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


$perl->perl_code("\nuse Bogus::NonExistant::Module");
like($app->test_run_machine, qr/Can't locate Bogus.* at your code line 2/i, 
  'problem compiling bad code was reported correctly');
$sink->reset;
