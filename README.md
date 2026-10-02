# uShuffle-perl

[![CI](https://github.com/mtw/ushuffle-perl/actions/workflows/ci.yml/badge.svg)](https://github.com/mtw/ushuffle-perl/actions/workflows/ci.yml)
[![CPAN version](https://img.shields.io/cpan/v/Ushuffle)](https://metacpan.org/dist/Ushuffle)
[![License](https://img.shields.io/badge/license-BSD-blue.svg)](Ushuffle/LICENSE)

A Perl interface to [uShuffle](https://doi.org/10.1186/1471-2105-9-192), a C library that shuffles a sequence while preserving its exact k-let counts.

Shuffling a nucleotide sequence with k=2 gives a random sequence with the same dinucleotide counts as the original; with k=3 the trinucleotide counts are kept, and so on. Such shuffles are the usual null model for judging whether a feature of a biological sequence, such as the folding energy of an RNA or the number of occurrences of a motif, is more than its composition would produce by chance.

```perl
use Ushuffle qw(shuffle set_seed);

# one shuffle that keeps all dinucleotide counts of the input
my $shuffled = shuffle('ACACGUAGAUGGGGA', 2);

# many shuffles of the same sequence
my $shuffler = Ushuffle::Shuffler->new('ACACGUAGAUGGGGA', 2);
print $shuffler->shuffle, "\n" for 1 .. 100;

# reproducible output
set_seed(42);
```

## What a shuffle preserves

For a let size k, every shuffle

- contains each k-let exactly as often as the original sequence, and therefore each shorter let as well, down to the single letters;
- starts and ends with the same k-1 letters as the original;
- is drawn with equal probability from all sequences that meet these two conditions.

With k=1 this is a plain permutation of the letters. Sequences need not be biological: any string of bytes other than NUL can be shuffled.

## Installation

You need Perl 5.10.1 or later, a C compiler, and a C library that provides `random()` and `srandom()`. No Perl modules outside the core are required.

From CPAN:

```sh
cpanm Ushuffle
```

From a checkout:

```sh
git clone https://github.com/mtw/ushuffle-perl.git
cd ushuffle-perl
make            # runs perl Makefile.PL in Ushuffle/ and builds
make test
cd Ushuffle && make install
```

The distribution itself is the `Ushuffle/` directory, which can also be built the usual way:

```sh
cd Ushuffle
perl Makefile.PL
make
make test
make install
```

It is tested on Linux with every stable Perl series from 5.10 to 5.44, built with and without thread support, and on macOS (Apple Silicon) with Perl 5.34 and 5.44. Windows is not supported, because the library needs `random()` and `srandom()`.

## Usage

### Functions

Both can be imported on request; nothing is exported by default.

| Function | Purpose |
|---|---|
| `shuffle($sequence, $k)` | Returns one shuffle of `$sequence` for let size `$k`. The input is not modified. |
| `set_seed($seed)` | Seeds the random number generator, for reproducible shuffles. |

### Shuffler objects

`Ushuffle::Shuffler` prepares a sequence once and then hands out any number of shuffles, which is about twice as fast as calling `shuffle` every time.

| Method | Purpose |
|---|---|
| `Ushuffle::Shuffler->new($sequence, $k)` | Creates a shuffler; it keeps its own copy of the sequence. |
| `$shuffler->shuffle` | Returns a new shuffle. |
| `$shuffler->sequence` | The sequence the shuffler was created with. |
| `$shuffler->k` | The let size the shuffler was created with. |

Several shufflers can be used side by side, but the library keeps only one sequence prepared at a time, so the speed advantage is lost while shufflers take turns. Finish with one sequence before moving to the next.

### Random numbers

The generator is seeded from the clock and the process id when the module is loaded, so separate runs give different shuffles. Call `set_seed` for reproducible ones. After `set_seed($seed)`, a new shuffler returns the same shuffles that the library's `ushuffle` command-line program prints for the same sequence, let size and `-seed $seed` on the same system.

### Threads

The module can be used from several threads at once. Calls into the library are serialized, so threads do not make shuffling faster; use separate processes for that. Each thread creates its own shufflers, and all threads share one random number generator.

### Errors

`shuffle` and `Ushuffle::Shuffler->new` die if the sequence is undefined, contains a NUL byte or a character above 255, or if `$k` is not a positive integer.

The full documentation is in the POD of [`Ushuffle`](Ushuffle/lib/Ushuffle.pm) and [`Ushuffle::Shuffler`](Ushuffle/lib/Ushuffle/Shuffler.pod); after installation, `perldoc Ushuffle` shows it.

## Performance

Time per shuffle with k=2, measured on an Apple M1 Pro with Perl 5.44:

| Sequence length | `$shuffler->shuffle` | `shuffle()` |
|---|---|---|
| 100 | 0.9 µs | 1.8 µs |
| 1,000 | 7 µs | 14 µs |
| 10,000 | 65 µs | 181 µs |

Preparing a sequence temporarily takes roughly 30 bytes of memory per letter.

## The bundled library

`Ushuffle/ushufflelib/` contains `ushuffle.c` and `ushuffle.h`, unmodified, from the master branch of [s-will/ushuffle](https://github.com/s-will/ushuffle), the source of the bioconda `ushuffle` package, at commit [2c4b8f3](https://github.com/s-will/ushuffle/commit/2c4b8f3) of 1 October 2026. That is release 1.2.2 plus a fix for an integer overflow in the library's hash function, which crashed it or slowed it down by an order of magnitude on sequences of tens of millions of letters. The fix originated in this project and was merged upstream as [pull request #1](https://github.com/s-will/ushuffle/pull/1).

## Repository layout

| Path | Contents |
|---|---|
| `Ushuffle/` | The Perl distribution |
| `Ushuffle/Ushuffle.xs` | The binding |
| `Ushuffle/lib/` | The module and its documentation |
| `Ushuffle/ushufflelib/` | The bundled uShuffle library |
| `Ushuffle/t/` | The test suite |
| `Makefile` | Wrapper with `all`, `test` and `clean` targets |
| `.github/workflows/ci.yml` | Continuous integration |

## Testing

`make test` runs the suite. Besides the properties above it checks, for short sequences, that exactly the valid shuffles are produced and that they are equally likely. On GitHub the suite runs for every push on Linux with the recent Perl releases and the oldest supported one, each with and without thread support, and on macOS.

One test is off by default because it needs about 1 GB of memory: it shuffles 25 million nucleotides, the case that triggered the hash overflow.

```sh
cd Ushuffle && EXTENDED_TESTING=1 make test
```

## Citation

If you use this module, please cite the uShuffle paper:

> Minghui Jiang, James Anderson, Joel Gillespie and Martin Mayne. uShuffle: a useful tool for shuffling biological sequences while preserving the k-let counts. *BMC Bioinformatics* 9:192, 2008. <https://doi.org/10.1186/1471-2105-9-192>

To refer to this software itself, use the metadata in [`CITATION.cff`](CITATION.cff) or the "Cite this repository" entry on GitHub.

## Licence

The Perl interface is Copyright (c) 2026 Michael T. Wolfinger. The uShuffle library is Copyright (c) 2007 Minghui Jiang, James Anderson, Joel Gillespie and Martin Mayne. Both are distributed under the BSD licence in [`Ushuffle/LICENSE`](Ushuffle/LICENSE).
