use strict;
use warnings;

use Test::More tests => 21;

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

use_ok('LineGear');
my $sink = LineGear->new(id => 2);
isa_ok($sink, 'LineGear');
is($sink->id, 2, 'id carried through from constructor');
$sink->prime;


use_ok('Sprog::Gear::Grep');
my $grep = Sprog::Gear::Grep->new(id => 1);
isa_ok($grep, 'Sprog::Gear::Grep');

is($grep->id, 1, 'id carried through from constructor');
ok($grep->has_input, 'has input');
ok($grep->has_output, 'has output');
is($grep->title, 'Pattern Match', 'title looks ok');
like($grep->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
ok($grep->ignore_case, 'case-insensitive matching defaults on');
ok(!$grep->invert_match, 'inverted matching defaults off');


use_ok('DummyMachine');
my $machine = DummyMachine->new;
isa_ok($machine, 'DummyMachine');


$grep->next($sink);
isa_ok($grep->last, 'LineGear');

my $ref = $grep->serialise;
is($ref->{NEXT}, 2, 'successfully got next gear id for serialising');

$grep->machine($machine);
$grep->prime;

$grep->msg_in(data => $data);
$grep->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');


$grep->pattern('');
$grep->prime;
$sink->reset;

$grep->msg_in(data => $data);
$grep->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$grep->pattern('etc');
$grep->prime;
$sink->reset;

$grep->msg_in(data => $data);
$grep->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
  "/var/lib/EtchingsLogo\n",
], "matched using default case-insensitive matching");


$grep->pattern('etc');
$grep->ignore_case(0);
$grep->prime;
$sink->reset;

$grep->msg_in(data => $data);
$grep->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/etc/syslog.conf\n",
], "switched to case-sensitive match");


$grep->pattern('log');
$grep->ignore_case(1);
$grep->invert_match(1);
$grep->prime;
$sink->reset;

$grep->msg_in(data => $data);
$grep->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], [
  "/etc/hosts\n",
  "/usr/bin/cat\n",
  "/usr/bin/grep\n",
  "/usr/bin/ls\n",
], "back to case-insensitive but inverted matching enabled");

