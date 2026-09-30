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

sub bad_shuffles {
    my ($shuffler, $n) = @_;
    my ($seq, $k) = ($shuffler->sequence, $shuffler->k);
    my $bad = 0;
    for (1 .. $n) {
        my $out = $shuffler->shuffle;
        $bad++ if length $out != length $seq or klets($out, $k) ne klets($seq, $k);
    }
    return $bad;
}

my $seq      = 'ACACGUAGAUGGGGA';
my $shuffler = Ushuffle::Shuffler->new($seq, 2);

isa_ok $shuffler, 'Ushuffle::Shuffler';
is $shuffler->sequence, $seq, 'sequence';
is $shuffler->k,        2,    'k';
is bad_shuffles($shuffler, 100), 0, '100 shuffles keep the dinucleotide counts';

{
    my %seen;
    $seen{ $shuffler->shuffle }++ for 1 .. 50;
    cmp_ok scalar keys %seen, '>', 1, 'successive shuffles differ';
}

# the shuffler must not depend on the scalar it was created from
{
    my $other;
    {
        my $source = 'UUGGCCAAUGCAUGCAGGCC';
        $other = Ushuffle::Shuffler->new($source, 3);
        $source = 'x' x 20;
    }
    my @filler = map { 'Z' x 20 } 1 .. 1000;
    is $other->sequence, 'UUGGCCAAUGCAUGCAGGCC', 'keeps its own copy of the sequence';
    is bad_shuffles($other, 20), 0, 'shuffles after the source scalar is gone';
}

# several shufflers, of different lengths and let sizes, used in turn
{
    my @shufflers = (
        Ushuffle::Shuffler->new('ACGU' x 3,                     2),
        Ushuffle::Shuffler->new('AACCGGUUACGUAGCUAGCUAGGAUC' x 8, 3),
        Ushuffle::Shuffler->new('GAUUACA',                      1),
        Ushuffle::Shuffler->new('',                             2),
        Ushuffle::Shuffler->new('ACGUACGU',                     50),
    );
    my $bad = 0;
    for my $round (1 .. 30) {
        $bad += bad_shuffles($_, 1) for @shufflers;
        my $plain = shuffle('GGGGCCCCAAAAUUUUGCGC', 2);
        $bad++ if klets($plain, 2) ne klets('GGGGCCCCAAAAUUUUGCGC', 2);
    }
    is $bad, 0, 'interleaved shufflers and shuffle() calls do not disturb each other';
    is $shufflers[3]->shuffle, '',         'shuffler for an empty sequence';
    is $shufflers[4]->shuffle, 'ACGUACGU', 'shuffler with k above the length';
}

# a destroyed shuffler must not take the state of a live one with it
{
    my $keep = Ushuffle::Shuffler->new('ACGUUGCAACGGUUAC', 2);
    $keep->shuffle;
    {
        my $gone = Ushuffle::Shuffler->new('AAAACCCC', 2);
        $gone->shuffle;
    }
    is bad_shuffles($keep, 20), 0, 'unaffected by another shuffler being destroyed';
}

{
    @My::Shuffler::ISA = ('Ushuffle::Shuffler');
    my $sub = My::Shuffler->new($seq, 2);
    isa_ok $sub, 'My::Shuffler';
    is bad_shuffles($sub, 5), 0, 'subclass instance shuffles';
}

done_testing;
