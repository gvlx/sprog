package Sprog::GtkView::Chrome;

use strict;
use warnings;

use MIME::Base64;

use constant MINI_GEAR_ICON_WIDTH   => 47;
use constant MINI_GEAR_ICON_HEIGHT  => 22;
use constant MINI_GEAR_ICON_COLOURS => (
  '  c None',
  '# c #000000',
  '. c #C9C9C9',
);

my %mini_gear_icon_cache;

my %mini_gear_icon_top = (

  '_' => [
          '                                               ',
          '                                               ',
          '    #######################################    ',
          '   #########################################   ',
          '  ###.....................................###  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
  ],

  'P' => [
          '                                               ',
          '                                               ',
          '    #######         #######################    ',
          '   ########         ########################   ',
          '  ###....##         ##....................###  ',
          '  ##.....##         ##.....................##  ',
          '  ##.....#############.....................##  ',
          '  ##.....#############.....................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
  ],

  'A' => [
          '                                               ',
          '                                               ',
          '    #######         #######################    ',
          '   ########         ########################   ',
          '  ###....##  #####  ##....................###  ',
          '  ##.....##  #####  ##.....................##  ',
          '  ##.....######.######.....................##  ',
          '  ##.....######.######.....................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
  ],

  'H' => [
          '                                               ',
          '                                               ',
          '    #######         #######################    ',
          '   ########         ########################   ',
          '  ###....##         ##....................###  ',
          '  ##.....####     ####.....................##  ',
          '  ##.......#### ####.......................##  ',
          '  ##.........#####.........................##  ',
          '  ##...........#...........................##  ',
          '  ##.......................................##  ',
          '  ##.......................................##  ',
  ],

);

my %mini_gear_icon_bot = (

  '_' => [
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ###.....................................###  ',
          '   #########################################   ',
          '    #######################################    ',
          '                                               ',
          '                                               ',
          '                                               ',
          '                                               ',
          '                                               ',
          '                                               '
  ],

  'P' => [
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ###.....................................###  ',
          '   ########.........########################   ',
          '    #######.........#######################    ',
          '         ##.........##                         ',
          '         ##.........##                         ',
          '         #############                         ',
          '         #############                         ',
          '                                               ',
          '                                               '
  ],

  'A' => [
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ###.....................................###  ',
          '   ########.........########################   ',
          '    #######.........#######################    ',
          '         ##..#####..##                         ',
          '         ##..#####..##                         ',
          '         ###### ######                         ',
          '         ###### ######                         ',
          '                                               ',
          '                                               '
  ],

  'H' => [
          '  ##.......................................##  ',
          '  ##.......................................##  ',
          '  ###.....................................###  ',
          '   ########.........########################   ',
          '    #######.........#######################    ',
          '         ##.........##                         ',
          '         ####.....####                         ',
          '           ####.####                           ',
          '             #####                             ',
          '               #                               ',
          '                                               '
  ],

);

sub about_logo {
  my $png_data = decode_base64(<<'EOF');
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
HT7+B67/AKql/D/6JY9WAAAAAElFTkSuQmCC
EOF
  my $loader = Gtk2::Gdk::PixbufLoader->new;
  $loader->write ($png_data);
  $loader->close;
  return $loader->get_pixbuf;
}


sub cogs {
  return(

    Gtk2::Gdk::Pixbuf->new_from_xpm_data(
      '24 27 33 1',
      ' 	c None',
      '.	c #030303',
      '+	c #827D6F',
      '@	c #2E2D2B',
      '#	c #D9D9D6',
      '$	c #B8B6B2',
      '%	c #67645B',
      '&	c #989280',
      '*	c #43423F',
      '=	c #242321',
      '-	c #5E5B53',
      ';	c #ADADAB',
      '>	c #191917',
      ',	c #D1CFCB',
      'Z	c #A69F86',
      ')	c #51504F',
      '!	c #8D8772',
      '~	c #756E59',
      '{	c #E3E1DB',
      ']	c #121212',
      '^	c #C6C4C1',
      '/	c #969696',
      '(	c #3A3832',
      '_	c #F1EFEA',
      ':	c #6E6E6D',
      '<	c #8A8A8A',
      '[	c #A3A29E',
      '}	c #0E0E0D',
      '|	c #4D4A41',
      '1	c #A29A7F',
      '2	c #79766D',
      '3	c #C0BEB8',
      '4	c #0A0A0A',
      '         )))))-         ',
      '         )#__+)         ',
      '    :)@)[|_;1.)  <<<    ',
      '   -*$_@||_1Z4* 2)<(-   ',
      '  <*#_$!**_ZZ}*:|1{/*%  ',
      '  <-_Z1&$/_ZZ)-(;{$~.)$ ',
      '  +**~&11$^ZZ13{{3!..@; ',
      '  $-@|311ZZZZ11&&!..>*; ',
      '  ;<*}{11~||)-!&&*.>@2$ ',
      '-)*(@~_1%*4]]>[Z!%@>@*|-',
      ')^___{,1*4====@3!+&3,^))',
      '){&!!&&&|=**(@>^!++~~~.)',
      '|{!!!!&&-*-%-*=^!++~~-.*',
      '*-...(!!+(:2:-*3+(.....*',
      '*=>]4*;!&$-2:)3[+)>4}>@*',
      '&:*@>4,!![$^$3[++2(=]@%<',
      '/+-@>+{!!!!++!+2+~~-(=:[',
      ';[-@&#3!*%+++>..|~~*.@<;',
      ' $2:#;!4.(1+2.=4*%-.}(/ ',
      '  2(!%4.=.322.444|..=)$ ',
      '  ;*=>.=44,2~.4@]4=>(<$ ',
      '  ;<(>>}=},~%.>))@@@%[$ ',
      '  ;/:***|>-...=22%%:<[  ',
      '   [<2%:2@=}}=(///</[$  ',
      '   $[////+-**-<;$;;;    ',
      '     $$$;/2%%+/$        ',
      '         $//<[;         '
    ),

    Gtk2::Gdk::Pixbuf->new_from_xpm_data(
      '24 27 33 1',
      ' 	c None',
      '.	c #090B07',
      '+	c #171714',
      '@	c #20201D',
      '#	c #2A2B27',
      '$	c #35342E',
      '%	c #3B3727',
      '&	c #40403A',
      '*	c #494A47',
      '=	c #504C40',
      '-	c #544F3B',
      ';	c #545551',
      '>	c #60615D',
      ',	c #6F6956',
      'Z	c #6C6E6B',
      ')	c #767874',
      '!	c #847F6C',
      '~	c #878065',
      '{	c #82827D',
      ']	c #8D8E8A',
      '^	c #978F75',
      '/	c #9A9481',
      '(	c #9A9B95',
      '_	c #A69D83',
      ':	c #A6A7A2',
      '<	c #B1AB97',
      '[	c #B2B4B0',
      '}	c #C2BCA7',
      '|	c #C2BFB0',
      '1	c #BEC0BC',
      '2	c #CBC7B7',
      '3	c #C7C9C6',
      '4	c #DBDAD3',
      '      :Z>*Z[ );):       ',
      '     ]>{(|{;(;4[ZZ]     ',
      '     {,442!&;(42|,>     ',
      '    :Z&/__~%*4<_&&]     ',
      '  : [Z$-^_<((4_^.*[ [   ',
      ' ]>;ZZ&%|^_<3}/,@;:{)]: ',
      ' ;13]$*{2___|__,;*>Z{ZZ[',
      '])3<34[4<!~,!</<<{:33(;]',
      '>/_^^_}|^,===,!/<34|/,#Z',
      '*%.%,~^^,%...+<(/^/,$.@)',
      '>#+..-/^=.+++.$1/!&..+#]',
      ')*#.$,^!&@###@.1/,%.@$>[',
      '{;#+.[//=$&*&#+3^~,*#*] ',
      ')*;>(|//!#=;;&&1!!/[:)*{',
      ')Z[3|/!/([*=**1:,!,!!)=)',
      '>;:(/==,!:|111:,$+=,,.&:',
      '>$=#+.+,!!!!/!!,%...@.; ',
      ')#+.+@.{!!=+$,!,%@.+.#{ ',
      '{*@++.@1!!.@.#,,,%+$**: ',
      ']>*$#+Z:,=...&,,-##*)([ ',
      ':{ZZ;@!Z,@.+.@-&..#)][  ',
      '[:]]Z##.+.+&#++..#>:[   ',
      '  [:{;#+.+*>*#@+#;]     ',
      '   [])*&**){)*&*Z][     ',
      '    :]ZZZ]::]{Z)][      ',
      '    [:(]([[[[((:[       ',
      '       [[     [[        ',
    ),

  );
}


sub mini_gear_icon {
  my $class    = shift;
  my $type_in  = shift || '_';
  my $type_out = shift || '_';

  # Return cached pixmap if available

  my $key = "$type_in$type_out";
  return $mini_gear_icon_cache{$key} if $mini_gear_icon_cache{$key};

  # Otherwise start building from a transparent rectangle of correct size

  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data(
    sprintf('%u %u 3 1', MINI_GEAR_ICON_WIDTH, MINI_GEAR_ICON_HEIGHT),
    MINI_GEAR_ICON_COLOURS,
    (' ' x MINI_GEAR_ICON_WIDTH) x MINI_GEAR_ICON_HEIGHT
  );

  # Add shape for top half

  my($bits, $pixm);
  $bits = $mini_gear_icon_top{$type_in} || $mini_gear_icon_top{'_'};
  $pixm = Gtk2::Gdk::Pixbuf->new_from_xpm_data(
    sprintf('%u %u 3 1', MINI_GEAR_ICON_WIDTH, MINI_GEAR_ICON_HEIGHT/2),
    MINI_GEAR_ICON_COLOURS,
    @$bits
  );
  $pixm->copy_area(0, 0, MINI_GEAR_ICON_WIDTH-1, MINI_GEAR_ICON_HEIGHT/2,
                   $pixbuf, 0, 0);

  # Add shape for bottom half

  $bits = $mini_gear_icon_bot{$type_out} || $mini_gear_icon_bot{'_'};
  $pixm = Gtk2::Gdk::Pixbuf->new_from_xpm_data(
    sprintf('%u %u 3 1', MINI_GEAR_ICON_WIDTH, MINI_GEAR_ICON_HEIGHT/2),
    MINI_GEAR_ICON_COLOURS,
    @$bits
  );
  $pixm->copy_area(0, 0, MINI_GEAR_ICON_WIDTH-1, MINI_GEAR_ICON_HEIGHT/2-1,
                   $pixbuf, 0, MINI_GEAR_ICON_HEIGHT/2);


  return $mini_gear_icon_cache{$key} = $pixbuf;
}

1;

