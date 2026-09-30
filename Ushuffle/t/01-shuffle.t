use strict;
use warnings;

use Test::More;

use Ushuffle qw(shuffle);

# the k-let counts of a sequence as one comparable string
sub klets {
    my ($seq, $k) = @_;
    my %n;
    $n{ substr $seq, $_, $k }++ for 0 .. length($seq) - $k;
    return join ',', map {"$_=$n{$_}"} sort keys %n;
}

my $seq = 'ACACGUAGAUGGGGA';

for my $k (1 .. 4) {
    my $out = shuffle($seq, $k);
    is length $out, length $seq, "k=$k: length is kept";
    is klets($out, $k), klets($seq, $k), "k=$k: $k-let counts are kept";
}

is Ushuffle::shuffle($seq, 2) =~ tr/ACGU//, length $seq,
    'callable by its full name';

# random sequences over several alphabets, lengths and let sizes
srand 1;
for my $alphabet ('ACGU', 'AC', 'ACDEFGHIKLMNPQRSTVWY', "A\xE9\xFF") {
    my @letters = split //, $alphabet;
    my $bad = 0;
    for (1 .. 500) {
        my $len = 1 + int rand 80;
        my $k   = 1 + int rand 7;
        my $in  = join '', map { $letters[ rand @letters ] } 1 .. $len;
        my $out = shuffle($in, $k);
        $bad++
            if length $out != $len
            or klets($out, $k) ne klets($in, $k)
            or klets($out, 1) ne klets($in, 1);
    }
    is $bad, 0, sprintf 'random sequences over %d letters keep their k-let counts',
        scalar @letters;
}

{
    my $long = join '', map { (qw(A C G U))[ rand 4 ] } 1 .. 200;
    my %seen;
    $seen{ shuffle($long, 2) }++ for 1 .. 20;
    cmp_ok scalar keys %seen, '>', 1, 'repeated calls give different shuffles';
}

is shuffle($seq, length $seq),      $seq, 'k equal to the length returns a copy';
is shuffle($seq, 1000),             $seq, 'k above the length returns a copy';
is shuffle('',   2),                '',   'empty sequence';
is shuffle('A',  1),                'A',  'single letter';
is shuffle('AAAAAAAA', 3),          'AAAAAAAA', 'homopolymer';
is shuffle(12345, 5),               '12345',    'numbers are treated as strings';

# the input, and scalars sharing its buffer, must be left alone
{
    my $in     = 'ACGUUGCAACGGUUAC';
    my $shared = $in;
    my $out    = shuffle($in, 2);
    is $in,     'ACGUUGCAACGGUUAC', 'input is not modified';
    is $shared, 'ACGUUGCAACGGUUAC', 'a copy of the input is not modified';

    for my $round (1 .. 3) {
        my $literal = 'ACGUUGCAACGGUUAC';
        $literal = shuffle($literal, 2);
        is klets($literal, 2), klets($in, 2),
            "round $round: assigning the result to its own input";
    }
}

# characters below 256 work whatever the internal encoding of the string
{
    my $in = "A\xE9CA\xE9GA\xE9C";
    utf8::upgrade(my $upgraded = $in);
    my $out = shuffle($upgraded, 2);
    is klets($out, 2), klets($in, 2), 'upgraded string is shuffled by character';
    is $upgraded, $in, 'upgraded input is unchanged';
}

done_testing;
