use strict;
use warnings;

use Test::More tests => 26;

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
use_ok('Sprog::Gear::FindReplace');
use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'DummyApp',
  '/app/machine' => 'DummyMachine',
);


my $sink = LineGear->new(id => 2);
isa_ok($sink, 'LineGear');
$sink->prime;


my $subst = Sprog::Gear::FindReplace->new(id => 1, app => $app);
isa_ok($subst, 'Sprog::Gear::FindReplace');
isa_ok($subst, 'Sprog::Gear::InputByLine');
isa_ok($subst, 'Sprog::Gear');

ok($subst->has_input, 'has input');
ok($subst->has_output, 'has output');
is($subst->title, 'Find and Replace', 'title looks ok');
like($subst->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
ok($subst->ignore_case, 'case-insensitive matching defaults on');
ok($subst->global_replace, 'global replacement defaults on');
is($subst->pattern, '', 'default pattern is blank');
is($subst->replacement, '', 'default replacement is blank');


isa_ok($app->machine, 'DummyMachine');


$subst->next($sink);
isa_ok($subst->last, 'LineGear');

$subst->machine($app->machine);
$subst->prime;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');


$subst->pattern(undef);
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$subst->pattern('etc');
$subst->replacement('ETC');
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

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
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

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
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

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
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

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
$subst->prime;

like($app->alerts, qr{Error setting up find/replace\s*Unmatched}s,
  "correct alert generated when error in pattern");
$app->alerts('');


$subst->pattern('log');
$subst->replacement('$bogus');
$subst->prime;

like($app->alerts, qr{Error setting up find/replace.*bogus}s,
  "correct alert generated when error in pattern");
$app->alerts('');


$subst->global_replace(1);
$subst->pattern('/bin/(.*)');
$subst->replacement('/\U$1\E');
$subst->prime;
$sink->reset;

$subst->msg_in(data => $data);
$subst->turn_once;
1 while($sink->turn_once);

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
