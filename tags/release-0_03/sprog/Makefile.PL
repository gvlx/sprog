use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Sprog',
    VERSION_FROM      => 'lib/Sprog.pm',
    PREREQ_PM         => {
                           Gtk2               => undef,
                           Gnome2::Canvas     => undef,
                           Gtk2::GladeXML     => undef,
                           Class::Accessor    => undef,
                           Test::Simple       => 0.41,
                         },
    EXE_FILES         => [ qw(bin/sprog) ],
    ($] >= 5.005 ? (
      AUTHOR          => 'Grant McLean <grant@cpan.org>',
      ABSTRACT_FROM   => 'lib/Sprog.pm',
    ) : () ),
);
