.PHONY: all clean cleanall makefiles makefiles-lib checkmakefiles


all: checkmakefiles clean
	+$(MAKE) -C src all

clean: checkmakefiles
	+$(MAKE) -C src clean

cleanall: checkmakefiles
	@+$(MAKE) -C src MODE=release clean
	@+$(MAKE) -C src MODE=debug clean

MAKEMAKE_OPTIONS := -f --deep -o ncs-testbench -O out -I. \
	-L$$MCR_ROOT/runtime/glnxa64 -lmwmclmcrrt \
	-L$$MCR_ROOT/bin/glnxa64 \
	'-L../../matlab-scheduler/out/$$(CONFIGNAME)/src' '-lmatlab-scheduler$$(D)' \
	-L../../libncs_matlab/out -lncs_matlab \
	'-L../../libncs_omnet/out/$$(CONFIGNAME)/src' '-llibncs_omnet$$(D)' \
	'-L../../inet/out/$$(CONFIGNAME)/src' '-lINET$$(D)'

makefiles: makefiles-lib

makefiles-lib:
	cd src && opp_makemake $(MAKEMAKE_OPTIONS)

checkmakefiles:
	@if [ ! -f src/Makefile ]; then \
	echo; \
	echo '========================================================================'; \
	echo 'src/Makefile does not exist. Please use "make makefiles" to generate it!'; \
	echo '========================================================================'; \
	echo; \
	exit 1; \
	fi
