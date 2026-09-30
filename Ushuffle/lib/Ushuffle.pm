package Ushuffle;

use 5.008001;
use strict;
use warnings;

require Exporter;
our @ISA       = ('Exporter');
our @EXPORT_OK = qw(shuffle set_seed);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Ushuffle', $VERSION);

1;
__END__

=head1 NAME

Ushuffle - shuffle sequences while preserving their k-let counts

=head1 SYNOPSIS

  use Ushuffle qw(shuffle set_seed);

  # one shuffle that keeps all dinucleotide counts of the input
  my $shuffled = shuffle('ACACGUAGAUGGGGA', 2);

  # many shuffles of the same sequence
  my $shuffler = Ushuffle::Shuffler->new('ACACGUAGAUGGGGA', 2);
  print $shuffler->shuffle, "\n" for 1 .. 100;

  # reproducible output
  set_seed(42);

=head1 DESCRIPTION

This module is a Perl interface to the uShuffle library by Minghui Jiang,
James Anderson, Joel Gillespie and Martin Mayne. uShuffle produces uniformly
random permutations of a sequence that have exactly the same k-let counts as
the original, for any let size k: the same single-letter composition for k=1,
the same dinucleotide counts for k=2, and so on. Such shuffles are the usual
null model when assessing the significance of a feature of a biological
sequence.

=head1 FUNCTIONS

Both functions can be imported on request; nothing is exported by default.

=head2 shuffle

  my $shuffled = shuffle($sequence, $k);

Returns a new random permutation of C<$sequence> with the same k-let counts.
C<$k> must be a positive integer. With C<$k> of 1 the result is a plain
permutation of the letters; if C<$k> is at least the length of the sequence,
the only permutation with the same k-let counts is the sequence itself, and a
copy is returned.

=head2 set_seed

  set_seed($seed);

Seeds the random number generator with the unsigned integer C<$seed>. The
same seed followed by the same calls gives the same shuffles. See L</RANDOM
NUMBERS>.

=head1 Ushuffle::Shuffler

A shuffler prepares a sequence once and then hands out any number of
shuffles. This is about twice as fast as calling C<shuffle> repeatedly,
provided the shuffles of one shuffler are not interleaved with those of
another (see L</LIMITATIONS>).

=head2 new

  my $shuffler = Ushuffle::Shuffler->new($sequence, $k);

Takes the same arguments as C<shuffle>. The shuffler keeps its own copy of
the sequence.

=head2 shuffle

  my $shuffled = $shuffler->shuffle;

Returns a new shuffle on every call.

=head2 sequence

  my $sequence = $shuffler->sequence;

Returns the sequence the shuffler was created with.

=head2 k

  my $k = $shuffler->k;

Returns the let size the shuffler was created with.

=head1 RANDOM NUMBERS

The library draws its random numbers from the C library's C<random()>. The
generator is seeded from the clock and the process id when the module is
loaded, so separate runs give different shuffles; call C<set_seed> for
reproducible ones. The generator's state is shared by the whole process: a
child created with C<fork> continues with the same state as its parent and
should call C<set_seed> itself, and other code calling C<random()> or
C<srandom()> affects the shuffles.

=head1 LIMITATIONS

Sequences are treated as strings of bytes. A sequence must not contain NUL
bytes or characters above 255, and must be shorter than 2**31 bytes.

The library holds the prepared form of one sequence at a time. Using several
shufflers side by side is safe, but each switch from one shuffler to another,
and each call of the C<shuffle> function in between, makes the next
C<< $shuffler->shuffle >> prepare its sequence again.

The module is not thread safe, and shufflers are not carried over into new
threads. If it runs out of memory, the library terminates the process.

=head1 INCOMPATIBLE CHANGES

Version 0.01 exposed the C functions directly as
C<Ushuffle::shuffle($s, $t, $l, $k)>, C<Ushuffle::shuffle1($s, $l, $k)> and
C<Ushuffle::shuffle2($t)>, which wrote the result into a preallocated C<$t>.
Those have been replaced by the interface described above.

=head1 SEE ALSO

Minghui Jiang, James Anderson, Joel Gillespie and Martin Mayne. uShuffle: a
useful tool for shuffling biological sequences while preserving the k-let
counts. BMC Bioinformatics 9:192, 2008.
L<https://doi.org/10.1186/1471-2105-9-192>

The bundled library source is taken from
L<https://github.com/s-will/ushuffle>.

=head1 COPYRIGHT AND LICENSE

The uShuffle library in F<ushufflelib/> is distributed under the following
terms:

  Copyright (c) 2007
    Minghui Jiang, James Anderson, Joel Gillespie, and Martin Mayne.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
  3. The names of its contributors may not be used to endorse or promote
       products derived from this software without specific prior written
       permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
