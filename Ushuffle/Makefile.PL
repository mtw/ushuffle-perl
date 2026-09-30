use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/Ushuffle.pm');

WriteMakefile(
    NAME             => 'Ushuffle',
    VERSION_FROM     => 'lib/Ushuffle.pm',
    ABSTRACT_FROM    => 'lib/Ushuffle.pm',
    AUTHOR           => 'Michael T. Wolfinger <michael@wolfinger.eu>',
    LICENSE          => 'bsd',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM        => {},
    BUILD_REQUIRES   => { 'Test::More' => '0.88' },
    LIBS             => ['-lm'],
    INC              => '-I.',
    # Ushuffle.xs plus ushuffle_lib.c, which pulls in ushufflelib/ushuffle.c
    OBJECT           => '$(O_FILES)',
    depend           => {
        'ushuffle_lib$(OBJ_EXT)' => 'ushufflelib/ushuffle.c ushufflelib/ushuffle.h',
        'Ushuffle$(OBJ_EXT)'     => 'ushufflelib/ushuffle.h',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mtw/ushuffle-perl.git',
                web  => 'https://github.com/mtw/ushuffle-perl',
            },
            bugtracker => { web => 'https://github.com/mtw/ushuffle-perl/issues' },
        },
        # Ushuffle::Shuffler is defined in the XS file, where the indexer
        # would not find it
        provides => {
            'Ushuffle'           => { file => 'lib/Ushuffle.pm', version => $version },
            'Ushuffle::Shuffler' => { file => 'lib/Ushuffle.pm', version => $version },
        },
    },
);
