libuv-version     = 0.10.27
coreutils-version = 8.21
perl-version      = 5.18.1
ltp-version       = 20140422
opt-version       = 20140422
gdb-version       = 7.6.1
proot-version     = 3.2.2

libuv     = libuv-$(libuv-version)
coreutils = coreutils-$(coreutils-version)
perl      = perl-$(perl-version)
ltp       = ltp-$(ltp-version)
opt       = opt-$(opt-version)
gdb       = gdb-$(gdb-version)
proot     = PRoot-$(proot-version)

testsuites = $(libuv) $(perl) $(ltp) $(opt) $(gdb) $(proot) $(coreutils)
logs       = $(testsuites:=.log)

logs: $(logs)

.PHONY: clean
clean:
	rm -f $(logs)
	rm -fr $(testsuites)

.PHONY: distclean
 distclean: clean
	rm -f $(testsuites:=.tar.*)

######################################################################

$(libuv).tar.gz:
	wget https://github.com/joyent/libuv/archive/v$(libuv-version).tar.gz -O $@

$(libuv).log: $(libuv).tar.gz
	rm -fr $(libuv)
	tar -xf $<
	$(MAKE) -C $(libuv)
	($(MAKE) -C $(libuv) test 2>&1 || true) | tee $@

######################################################################

$(coreutils).tar.xz:
	wget http://ftp.gnu.org/gnu/coreutils/$(coreutils).tar.xz

$(coreutils).log: $(coreutils).tar.xz
	rm -fr $(coreutils)
	tar -xf $<
	cd $(coreutils) && ./configure
	$(MAKE) -C $(coreutils)
	($(MAKE) -C $(coreutils) check || true) | tee $@

######################################################################

$(perl).tar.gz:
	wget http://www.cpan.org/src/5.0/$(perl).tar.gz

$(perl).log: $(perl).tar.gz
	rm -fr $(perl)
	tar -xf $<
	cd $(perl) && ./configure.gnu
	$(MAKE) -C $(perl)
	($(MAKE) -C $(perl) check || true) | tee $@

######################################################################

$(ltp).tar.gz:
	wget https://github.com/linux-test-project/ltp/archive/$(ltp-version).tar.gz -O $@

$(ltp).log: $(ltp).tar.gz
	rm -fr $(ltp)
	tar -xf $<
	$(MAKE) -C $(ltp) autotools
	cd $(ltp) && ./configure --prefix=$(PWD)/$(ltp)/install
	$(MAKE) -C $(ltp)
	$(MAKE) -C $(ltp) install
	sed -i s/^msgctl10/#/ $(ltp)/install/runtest/syscalls # is too CPU intensive
	sed -i s/^msgctl11/#/ $(ltp)/install/runtest/syscalls # is too CPU intensive
	($(ltp)/install/runltp -f syscalls || true) | tee $@

######################################################################

$(opt).log: $(ltp).tar.gz
	rm -fr $(opt)
	mkdir $(opt)
	tar -C $(opt) -xf $< $(ltp)/testcases/open_posix_testsuite
	$(MAKE) -C $(opt)/$(ltp)/testcases/open_posix_testsuite  -j 1 # has broken // build
	($(MAKE) -C $(opt)/$(ltp)/testcases/open_posix_testsuite -j 1 test || true) | tee $@

######################################################################

$(gdb).tar.gz:
	wget http://ftp.gnu.org/gnu/gdb/$(gdb).tar.gz

$(gdb).log: $(gdb).tar.gz
	rm -fr $(gdb)
	tar -xf $<
	cd $(gdb) && ./configure
	$(MAKE) -C $(gdb)
	rm -f $(gdb)/gdb/testsuite/gdb.base/foll-fork.exp        # makes PRoot stall
	rm -f $(gdb)/gdb/testsuite/gdb.base/foll-vfork.exp       # makes PRoot stall
	rm -f $(gdb)/gdb/testsuite/gdb.base/watch_thread_num.exp # makes PRoot stall
	rm -f $(gdb)/gdb/testsuite/gdb.base/attach-twice.exp     # kills PRoot explicitly
	($(MAKE) -C $(gdb)/gdb/testsuite check-gdb.base1 check-gdb.base2 check-gdb.server || true) | tee $@

######################################################################

$(proot).tar.gz:
	wget https://github.com/cedric-vincent/proot/archive/v$(proot-version).tar.gz -O $@

$(proot).log: $(proot).tar.gz
	rm -fr $(proot)
	tar -xf $<
	$(MAKE) -C $(proot)/src
	($(MAKE) -C $(proot)/tests || true) | tee $@
