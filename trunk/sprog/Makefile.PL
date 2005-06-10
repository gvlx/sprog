use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Sprog',
    VERSION_FROM      => 'lib/Sprog.pm',
    PREREQ_PM         => {
                           'Gtk2'               => undef,
                           'Gnome2::Canvas'     => undef,
                           'Gtk2::GladeXML'     => undef,
                           'Test::Simple'       => 0.41,
                           'YAML'               => undef,
                           'MIME::Base64'       => undef,
                           'Pod::Simple'        => undef,
                         },
    EXE_FILES         => [ qw(bin/sprog) ],
    AUTHOR            => 'Grant McLean <grant@cpan.org>',
    ABSTRACT_FROM     => 'lib/Sprog.pm',
);

