use strict;
use warnings;

use Test::More tests => 62;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('Sprog::ClassFactory');

my $app = make_app(                 # Imported from ClassFactory.pm
  '/app/view'    => 'Dummy',
);

isa_ok($app, 'Sprog', 'app object');

my $db_class = $app->geardb;

can_ok($db_class, 'gear_class_info');

my $info = $db_class->gear_class_info;
is($info, undef, 'asking for info about nothing gets nothing');

$info = $db_class->gear_class_info('Sprog::Gear::BogusNonExistantGear');
is($info, undef, 'asking for info about bogus class gets nothing');

$info = $db_class->gear_class_info('Sprog::Gear::PerlBase');
is($info, undef, 'asking for info about a class without metadata gets nothing');

$info = $db_class->gear_class_info('Sprog::Gear::ReadFile');
isa_ok($info, 'Sprog::GearMetadata', 'info object for ReadFile gear');

is($info->class,    'Sprog::Gear::ReadFile', 'gear class name looks ok');
is($info->title,    'Read File',             'gear title looks ok');
is($info->type_in,  '_',                     'input  connector type looks ok');
is($info->type_out, 'P',                     'output connector type looks ok');
ok(defined($info->keywords),                 'gear has keywords');
like($info->keywords, qr/read file/,         'lc(title) is in keywords');

my(@gears, @match);
@gears = $db_class->search;
ok(@gears > 0, 'search found some gears');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 1, '  Sprog::Gear::ReadFile was in the list');

@match = grep { $_->class eq 'Sprog::Gear::CommandIn' } @gears;
ok(@match == 1, '  Sprog::Gear::CommandIn was in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextInput' } @gears;
ok(@match == 1, '  Sprog::Gear::TextInput was in the list');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 1, '  Sprog::Gear::Grep was in the list');
like($match[0]->keywords, qr/pattern match/, '    lc(title) is in keywords');
like($match[0]->keywords, qr/\bregex\b/, '    "regex" is in keywords too');
like($match[0]->keywords, qr/\bregular expression\b/,
'    "regular expression" is in keywords too');

@match = grep { $_->class eq 'Sprog::Gear::FindReplace' } @gears;
ok(@match == 1, '  Sprog::Gear::FindReplace was in the list');

@match = grep { $_->class eq 'Sprog::Gear::PerlCode' } @gears;
ok(@match == 1, '  Sprog::Gear::PerlCode was in the list');

@match = grep { $_->class eq 'Sprog::Gear::LowerCase' } @gears;
ok(@match == 1, '  Sprog::Gear::LowerCase was in the list');

@match = grep { $_->class eq 'Sprog::Gear::UpperCase' } @gears;
ok(@match == 1, '  Sprog::Gear::UpperCase was in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextWindow' } @gears;
ok(@match == 1, '  Sprog::Gear::TextWindow was in the list');

@match = grep { $_->class eq 'Sprog::Gear::ApacheLogParse' } @gears;
ok(@match == 1, '  Sprog::Gear::ApacheLogParse was in the list');

@match = grep { $_->class eq 'Sprog::Gear::PerlCodeHP' } @gears;
ok(@match == 1, '  Sprog::Gear::PerlCodeHP was in the list');


@gears = $db_class->search('_');
ok(@gears > 0, 'search for gears with no input connector got results');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 1, '  Sprog::Gear::ReadFile was in the list');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 0, '  Sprog::Gear::Grep was not in the list');


@gears = $db_class->search('*', '_');
ok(@gears > 0, 'search for gears with no output connector got results');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextWindow' } @gears;
ok(@match == 1, '  Sprog::Gear::TextWindow was in the list');


@gears = $db_class->search('P', 'P');
ok(@gears > 0, 'search for pipe-pipe gears got results');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 1, '  Sprog::Gear::Grep was in the list');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextWindow' } @gears;
ok(@match == 0, '  Sprog::Gear::TextWindow was not in the list');


@gears = $db_class->search('H', 'P');
ok(@gears > 0, 'search for record-pipe gears got results');

@match = grep { $_->class eq 'Sprog::Gear::PerlCodeHP' } @gears;
ok(@match == 1, '  Sprog::Gear::PerlCodeHP was in the list');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 0, '  Sprog::Gear::Grep was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextWindow' } @gears;
ok(@match == 0, '  Sprog::Gear::TextWindow was not in the list');


@gears = $db_class->search('P', 'H');
ok(@gears > 0, 'search for pipe-record gears got results');

@match = grep { $_->class eq 'Sprog::Gear::ApacheLogParse' } @gears;
ok(@match == 1, '  Sprog::Gear::ApacheLogParse was in the list');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 0, '  Sprog::Gear::Grep was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');

@match = grep { $_->class eq 'Sprog::Gear::TextWindow' } @gears;
ok(@match == 0, '  Sprog::Gear::TextWindow was not in the list');


@gears = $db_class->search('*', '*', 'gnurzlegribblewerber');
ok(@gears == 0, 'unlikely keyword search got no results');


@gears = $db_class->search('*', '*', 'grep');
ok(@gears > 0, 'sensible keyword search got results');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 1, '  Sprog::Gear::Grep was in the list');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');


@gears = $db_class->search('*', '*', 'Regex');
ok(@gears > 0, 'mixed case keyword search got results');

@match = grep { $_->class eq 'Sprog::Gear::Grep' } @gears;
ok(@match == 1, '  Sprog::Gear::Grep was in the list');

@match = grep { $_->class eq 'Sprog::Gear::FindReplace' } @gears;
ok(@match == 1, '  Sprog::Gear::FindReplace was in the list');

@match = grep { $_->class eq 'Sprog::Gear::ReadFile' } @gears;
ok(@match == 0, '  Sprog::Gear::ReadFile was not in the list');


@gears = $db_class->search('P', '*', 'Perl Code');
ok(@gears > 0, 'input type + keyword search got results');

@match = grep { $_->class eq 'Sprog::Gear::PerlCode' } @gears;
ok(@match == 1, '  Sprog::Gear::PerlCode was in the list');

@match = grep { $_->class eq 'Sprog::Gear::PerlCodeHP' } @gears;
ok(@match == 0, '  Sprog::Gear::PerlCodeHP was not in the list');


@gears = $db_class->search('H', 'P', 'Perl Code');
ok(@gears > 0, 'input type + keyword search got results');

@match = grep { $_->class eq 'Sprog::Gear::PerlCodeHP' } @gears;
ok(@match == 1, '  Sprog::Gear::PerlCodeHP was in the list');

@match = grep { $_->class eq 'Sprog::Gear::PerlCode' } @gears;
ok(@match == 0, '  Sprog::Gear::PerlCode was not in the list');

