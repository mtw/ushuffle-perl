#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "ushufflelib/ushuffle.h"

/*
 * The uShuffle library keeps the k-let graph of a single sequence in
 * file-level statics. Every Shuffler therefore owns a copy of its sequence,
 * and loaded_id records whose graph the library currently holds, so that the
 * graph is rebuilt when another Shuffler or a plain shuffle() call has
 * replaced it in the meantime. Ids start at 1 and are never reused; 0 means
 * "no Shuffler".
 */

typedef struct {
	char *seq;
	int len;
	int k;
	UV id;
} shuffler;

typedef shuffler *Ushuffle__Shuffler;

static UV next_id = 1;
static UV loaded_id = 0;

static const char *checked_sequence(pTHX_ SV *sv, int *len) {
	const char *s;
	STRLEN n;

	SvGETMAGIC(sv);
	if (!SvOK(sv))
		croak("Ushuffle: sequence is undefined");
	s = SvPVbyte(sv, n);
	if (n > (STRLEN) INT_MAX)
		croak("Ushuffle: sequence is too long");
	/* the library compares k-lets with strncmp */
	if (memchr(s, '\0', n))
		croak("Ushuffle: sequence contains a NUL byte");
	*len = (int) n;
	return s;
}

static int checked_k(pTHX_ SV *sv) {
	IV k;

	SvGETMAGIC(sv);
	k = SvOK(sv) ? SvIV(sv) : 0;
	if (k < 1)
		croak("Ushuffle: k must be a positive integer");
	return k > INT_MAX ? INT_MAX : (int) k;
}

/* one shuffle of the sequence (of length len) currently held by the library */
static SV *next_shuffle(pTHX_ int len) {
	SV *t;

	if (len == 0)
		return newSVpvn("", 0);
	t = newSV(len);
	SvPOK_only(t);
	shuffle2(SvPVX(t));
	SvPVX(t)[len] = '\0';
	SvCUR_set(t, len);
	return t;
}

static void seed_from_clock(pTHX) {
	struct timeval tv;

	gettimeofday(&tv, NULL);
	srandom((unsigned int) ((unsigned long) tv.tv_sec
		^ ((unsigned long) tv.tv_usec << 12)
		^ ((unsigned long) PerlProc_getpid() << 16)));
}

MODULE = Ushuffle		PACKAGE = Ushuffle

PROTOTYPES: DISABLE

BOOT:
	seed_from_clock(aTHX);

SV *
shuffle(sequence, k)
	SV *sequence
	SV *k
    PREINIT:
	const char *s;
	int len, let;
    CODE:
	let = checked_k(aTHX_ k);
	s = checked_sequence(aTHX_ sequence, &len);
	if (len > 0) {
		loaded_id = 0;
		shuffle1(s, len, let);
	}
	RETVAL = next_shuffle(aTHX_ len);
    OUTPUT:
	RETVAL

void
set_seed(seed)
	UV seed
    CODE:
	srandom((unsigned int) seed);

MODULE = Ushuffle		PACKAGE = Ushuffle::Shuffler

SV *
new(class, sequence, k)
	const char *class
	SV *sequence
	SV *k
    PREINIT:
	shuffler *self;
	const char *s;
	int len, let;
    CODE:
	let = checked_k(aTHX_ k);
	s = checked_sequence(aTHX_ sequence, &len);
	Newx(self, 1, shuffler);
	self->seq = savepvn(s, len);
	self->len = len;
	self->k = let;
	self->id = next_id++;
	RETVAL = sv_setref_pv(newSV(0), class, (void *) self);
    OUTPUT:
	RETVAL

SV *
shuffle(self)
	Ushuffle::Shuffler self
    CODE:
	if (self->len > 0 && loaded_id != self->id) {
		shuffle1(self->seq, self->len, self->k);
		loaded_id = self->id;
	}
	RETVAL = next_shuffle(aTHX_ self->len);
    OUTPUT:
	RETVAL

SV *
sequence(self)
	Ushuffle::Shuffler self
    CODE:
	RETVAL = newSVpvn(self->seq, self->len);
    OUTPUT:
	RETVAL

int
k(self)
	Ushuffle::Shuffler self
    CODE:
	RETVAL = self->k;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	Ushuffle::Shuffler self
    CODE:
	Safefree(self->seq);
	Safefree(self);

int
CLONE_SKIP(...)
    CODE:
	/* a Shuffler is a bare pointer; cloning it into a thread would free it twice */
	RETVAL = 1;
    OUTPUT:
	RETVAL
