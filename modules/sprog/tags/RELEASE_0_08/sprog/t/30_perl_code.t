use strict;
use warnings;

use Test::More tests => 22;

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
use_ok('Sprog::Gear::PerlCode');
use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'DummyApp',
  '/app/machine' => 'DummyMachine',
);


my $sink = LineGear->new(id => 2);
isa_ok($sink, 'LineGear');
$sink->prime;


my $perl = Sprog::Gear::PerlCode->new(id => 1, app => $app);
isa_ok($perl, 'Sprog::Gear::PerlCode');
isa_ok($perl, 'Sprog::Gear::InputByLine');
isa_ok($perl, 'Sprog::Gear');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

$perl->next($sink);
isa_ok($perl->last, 'LineGear');

$perl->machine($app->machine);
$perl->prime;

$perl->msg_in(data => $data);
$perl->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default');

$perl->perl_code(undef);
$perl->prime;
$sink->reset;

$perl->msg_in(data => $data);
$perl->turn_once;
1 while($sink->turn_once);

is_deeply([ $sink->lines ], \@all, 'All lines passed through by default 2');


$perl->perl_code('$_ = "*** $_"');
$perl->prime;
is($app->alerts, '', 'no problem compiling code');
$sink->reset;

$perl->msg_in(data => $data);
$perl->turn_once;
1 while($sink->turn_once);

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


$perl->perl_code("\nuse Bogus::NonExistant::Module");
$perl->prime;
like($app->alerts, qr/Can't locate Bogus.* at your code line 2/i, 
  'problem compiling bad code was reported correctly');
$sink->reset;


# This one is just for Devel::Cover which wants to see 'false' values
# returned by the pre/postamble methods.

$perl = BrokenPerlCode->new(id => 3, app => $app);
isa_ok($perl, 'BrokenPerlCode');
isa_ok($perl, 'Sprog::Gear::PerlCode');
isa_ok($perl, 'Sprog::Gear::InputByLine');
isa_ok($perl, 'Sprog::Gear');

$perl->prime;

exit;


package BrokenPerlCode;

use base qw(Sprog::Gear::PerlCode);

sub _sub_preamble  { return; }
sub _sub_postamble { return; }

sub _suppress_used_once_warning { $Sprog::Gear::PerlBase::GearDefaultProps; }
