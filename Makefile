LIB_PG_QUERY_TAG = 13-2.1.0

root_dir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TMPDIR = $(root_dir)/tmp
LIBDIR = $(TMPDIR)/libpg_query
LIBDIRGZ = $(TMPDIR)/libpg_query-$(LIB_PG_QUERY_TAG).tar.gz
FLATTENDIR = $(TMPDIR)/flatten
PROGDIR = $(TMPDIR)/prog

default: flatten_source fix_pg_config 
	make update_source

.PHONY: flatten_source fix_pg_config update_source

$(LIBDIR): $(LIBDIRGZ)
	mkdir -p $(LIBDIR)
	cd $(TMPDIR); tar -xzf $(LIBDIRGZ) -C $(LIBDIR) --strip-components=1

$(LIBDIRGZ):
	mkdir -p $(TMPDIR)
	curl -o $(LIBDIRGZ) https://codeload.github.com/lfittl/libpg_query/tar.gz/$(LIB_PG_QUERY_TAG)


SRCS = $(wildcard $(FLATTENDIR)/*.c)
PROGS = $(patsubst $(FLATTENDIR)/%.c,$(PROGDIR)/%.o,$(SRCS))

$(PROGDIR)/%.o: $(FLATTENDIR)/%.c
	mkdir -p $(PROGDIR)
	emcc -O3 -c $< -o $@ -I $(FLATTENDIR)/include

flatten_source: $(LIBDIR)
	mkdir -p $(FLATTENDIR)
	rm -f $(FLATTENDIR)/*.{c,h}
	rm -fr $(FLATTENDIR)/include

	# Reduce everything down to one directory
	cp -a $(LIBDIR)/src/* $(FLATTENDIR)/
	mv $(FLATTENDIR)/postgres/* $(FLATTENDIR)/
	rmdir $(FLATTENDIR)/postgres
	cp -a $(LIBDIR)/pg_query.h $(FLATTENDIR)/include

	# Make sure every .c file in the top-level directory is its own translation unit
	mv $(FLATTENDIR)/*_conds.c $(FLATTENDIR)/*_defs.c $(FLATTENDIR)/*_helper.c $(FLATTENDIR)/*_random.c $(FLATTENDIR)/include

	# Add Dependencies
	cp -a $(LIBDIR)/protobuf $(FLATTENDIR)/include/
	cp -a $(LIBDIR)/vendor/protobuf-c $(FLATTENDIR)/include/
	cp -a $(LIBDIR)/vendor/xxhash $(FLATTENDIR)/include/

	cp -a $(LIBDIR)/protobuf/* $(FLATTENDIR)/
	cp -a $(LIBDIR)/vendor/protobuf-c/* $(FLATTENDIR)/
	cp -a $(LIBDIR)/vendor/xxhash/* $(FLATTENDIR)/

fix_pg_config:
	echo "#undef HAVE_SIGSETJMP" >> $(FLATTENDIR)/include/pg_config.h
	echo "#undef HAVE_SPINLOCKS" >> $(FLATTENDIR)/include/pg_config.h
	echo "#undef PG_INT128_TYPE" >> $(FLATTENDIR)/include/pg_config.h

update_source: $(PROGS)
	em++ \
		-I $(FLATTENDIR)/include \
		-O3 --bind --no-entry --pre-js module.js\
		-s LLD_REPORT_UNDEFINED=1 \
		-s ASSERTIONS=0 \
		-s SINGLE_FILE=1 \
		-s ENVIRONMENT=web \
		-s WASM=0 \
		-o tmp/pg_query_raw.js $(PROGS) entry.cpp

	echo "var PgQuery = (function () {" > pg_query.js
	cat tmp/pg_query_raw.js >> pg_query.js
	echo "return { normalize: Module.normalize, parse: Module.parse, parse_plpgsql: Module.parse_plpgsql, fingerprint: Module.fingerprint };" >> pg_query.js
	echo "})();" >> pg_query.js
	echo "if (typeof module !== 'undefined') module.exports = PgQuery;" >> pg_query.js
	echo "if (typeof define === 'function') define(PgQuery);" >> pg_query.js

clean:
	-@ $(RM) -r $(TMPDIR)
