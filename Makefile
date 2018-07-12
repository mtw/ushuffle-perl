all:
	h2xs -O -n Ushuffle ./Ushuffle/ushufflelib/ushuffle.h
	cp Ushuffle/Makefile.PL_save Ushuffle/Makefile.PL
	cp Ushuffle/MANIFEST_save Ushuffle/MANIFEST
	cp Ushuffle/Ushuffle.xs_save Ushuffle/Ushuffle.xs
	cd Ushuffle; perl Makefile.PL
	make -C Ushuffle/
	make -C Ushuffle/ushufflelib
