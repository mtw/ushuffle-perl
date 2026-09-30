use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ushuffle',
    VERSION_FROM     => 'lib/Ushuffle.pm',
    ABSTRACT_FROM    => 'lib/Ushuffle.pm',
    AUTHOR           => 'Michael T. Wolfinger <michael@wolfinger.eu>',
    MIN_PERL_VERSION => '5.008001',
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
);
