.PHONY: all test clean

all: Ushuffle/Makefile
	$(MAKE) -C Ushuffle

Ushuffle/Makefile: Ushuffle/Makefile.PL
	cd Ushuffle && perl Makefile.PL

test: all
	$(MAKE) -C Ushuffle test

clean:
	if [ -f Ushuffle/Makefile ]; then $(MAKE) -C Ushuffle realclean; fi
