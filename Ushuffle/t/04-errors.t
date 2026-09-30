use strict;
use warnings;

use Test::More;

use Ushuffle qw(shuffle);

sub error_of {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

my $seq = 'ACACGUAGAUGGGGA';

for my $make (
    [ 'shuffle'       => sub { shuffle(@_) } ],
    [ 'Shuffler->new' => sub { Ushuffle::Shuffler->new(@_) } ],
    )
{
    my ($name, $call) = @$make;

    like error_of(sub { $call->(undef, 2) }), qr/sequence is undefined/,
        "$name: undefined sequence";
    like error_of(sub { $call->("AC\0GU", 2) }), qr/NUL byte/,
        "$name: NUL byte in sequence";
    like error_of(sub { $call->("AC\x{263A}GU", 2) }), qr/Wide character/,
        "$name: character above 255";
    like error_of(sub { $call->($seq, 0) }), qr/k must be a positive integer/,
        "$name: k of zero";
    like error_of(sub { $call->($seq, -3) }), qr/k must be a positive integer/,
        "$name: negative k";
    like error_of(sub { $call->($seq, undef) }), qr/k must be a positive integer/,
        "$name: undefined k";
    like error_of(sub { $call->($seq) }), qr/Usage: /, "$name: missing k";
}

like error_of(sub { my $out = 'a' x 15; Ushuffle::shuffle($seq, $out, 15, 2) }),
    qr/Usage: Ushuffle::shuffle\(sequence, k\)/,
    'the four-argument form of version 0.01 is rejected';
ok !Ushuffle->can('shuffle1') && !Ushuffle->can('shuffle2'),
    'shuffle1 and shuffle2 are gone';

like error_of(sub { Ushuffle::Shuffler::shuffle('not an object') }),
    qr/Ushuffle::Shuffler/, 'method called on a plain string';

is length shuffle($seq, 2), length $seq, 'still working after the errors';

done_testing;
