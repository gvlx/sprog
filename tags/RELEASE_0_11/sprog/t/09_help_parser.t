use strict;
use Sprog::TestHelper tests => 13;

use_ok('Sprog::HelpParser');

my $view = TestHelpSink->new;

isa_ok($view, 'TestHelpSink', 'view object');

my $parser = Sprog::HelpParser->new($view);

isa_ok($parser, 'Sprog::HelpParser',    'parser object     ');
isa_ok($parser, 'Pod::Simple::Methody', 'parser object also');

isnt($parser->_find_file('Sprog'),          undef, 'top-level .pm file found');
isnt($parser->_find_file('Sprog::Machine'), undef, '2nd-level .pm file found');
is  ($parser->_find_file('Sprog::xBoGuSx'), undef, 'bad .pm file not found');
isnt($parser->_find_file('Sprog::help::index'), undef, '.pod file found');
isnt($parser->_find_file('perlfunc'),       undef, 'system .pod file found');
isnt($parser->_find_file('DummyGear'),      undef, 'test .pm file found');

$parser->parse_topic('DummyGear');
ok(1, "didn't die while parsing a .pm file with no pod");

$parser = Sprog::HelpParser->new($view);   # New one needed for each parse
$parser->parse_topic('DummyApp');
ok(1, "didn't die while parsing a .pm file with pod");

is_deeply($view->content, [
    {
      'tag_names' => [ 'head1' ],
      'text' => 'NAME',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'para' ],
      'text' => 'DummyApp - For testing porpoises',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'head1' ],
      'text' => 'DESCRIPTION',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'para' ],
      'text' => 'The POD in this file is for testing ',
      'indent' => 0
    },
    {
      'link_type' => 'pod',
      'link_target' => 'Sprog::HelpParser'
    },
    {
      'tag_names' => [ 'para', 'link' ],
      'text' => 'Sprog::HelpParser',
      'indent' => 0
    },
    {
      'tag_names' => [ 'para' ],
      'text' => '. It serves no other purpose.',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'para' ],
      'text' => 'Please ',
      'indent' => 0
    },
    {
      'tag_names' => [ 'para', 'italic' ],
      'text' => 'ignore',
      'indent' => 0
    },
    {
      'tag_names' => [ 'para' ],
      'text' => ' it.',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'head2' ],
      'text' => 'Options',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => "\x{B7} ",
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => 'a ',
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet', 'bold' ],
      'text' => 'Bold',
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => ' word',
      'indent' => 1
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => "\x{B7} ",
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => 'a ',
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet', 'code' ],
      'text' => 'Code',
      'indent' => 1
    },
    {
      'tag_names' => [ 'bullet' ],
      'text' => ' word',
      'indent' => 1
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 1
    },
    {
      'tag_names' => [ 'verbatim' ],
      'text' => '  Verbatim  Text',
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    },
    {
      'tag_names' => [],
      'text' => "\n",
      'indent' => 0
    }
  ],

  'Got the expected output');

exit;



package TestHelpSink;

sub new {
  return bless { content => [ ] }, shift;
}

sub content { shift->{content} };

sub add_tagged_text {
  my($self, $text, $indent, $tag_names) = @_;

  push @{$self->{content}}, {
    text      => $text,
    indent    => $indent,
    tag_names => [ @$tag_names ],
  };
}
sub link_data {
  my($self, $type, $target) = @_;

  push @{$self->{content}}, {
    link_type   => $type,
    link_target => $target,
  };
}
