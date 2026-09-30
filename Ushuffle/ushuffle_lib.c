/*
 * Compiles the uShuffle library into the extension.
 *
 * ushufflelib/ holds ushuffle.c and ushuffle.h unmodified from
 * https://github.com/s-will/ushuffle (v1.2.2 plus the hcode overflow fix of
 * pull request #1). The source is included from here rather than placed next
 * to Ushuffle.xs because a file named ushuffle.c would collide with the
 * generated Ushuffle.c on case-insensitive file systems.
 */

#include "ushufflelib/ushuffle.c"
