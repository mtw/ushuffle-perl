use strict;
use warnings;

use Test::More;

use Ushuffle qw(shuffle set_seed);

srand 3;
my $seq = join '', map { (qw(A C G U))[ rand 4 ] } 1 .. 200;

sub draws {
    my ($seed) = @_;
    set_seed($seed);
    my $shuffler = Ushuffle::Shuffler->new($seq, 2);
    return join ' ', shuffle($seq, 2), shuffle($seq, 3), map { $shuffler->shuffle } 1 .. 3;
}

my $first = draws(42);
is draws(42),   $first, 'same seed, same shuffles';
isnt draws(43), $first, 'different seed, different shuffles';
is draws(42),   $first, 'seed can be set again';

# a fresh interpreter that loads the module and prints one shuffle
sub in_new_process {
    my ($code) = @_;
    my @inc = map {"-I$_"} grep { !ref } @INC;
    open my $fh, '-|', $^X, @inc, '-MUshuffle', '-e', $code
        or die "cannot run $^X: $!";
    my $out = do { local $/; <$fh> };
    close $fh or die "child perl failed: $?";
    return $out;
}

my $unseeded = qq{print Ushuffle::shuffle("$seq", 2)};
my $seeded   = qq{Ushuffle::set_seed(7); print Ushuffle::shuffle("$seq", 2)};

my $one = in_new_process($unseeded);
is length $one, length $seq, 'child process returns a shuffle';
isnt in_new_process($unseeded), $one, 'separate processes are seeded differently';
is in_new_process($seeded), in_new_process($seeded),
    'separate processes agree once given the same seed';

done_testing;
