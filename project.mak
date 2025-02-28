# This file is part of the Zarith library 
# http://forge.ocamlcore.org/projects/zarith .
# It is distributed under LGPL 2 licensing, with static linking exception.
# See the LICENSE file included in the distribution.
#   
# Copyright (c) 2010-2011 Antoine Miné, Abstraction project.
# Abstraction is part of the LIENS (Laboratoire d'Informatique de l'ENS),
# a joint laboratory by:
# CNRS (Centre national de la recherche scientifique, France),
# ENS (École normale supérieure, Paris, France),
# INRIA Rocquencourt (Institut national de recherche en informatique, France).

ifeq "$(shell $(OCAMLC) -config |grep ccomp_type)" "ccomp_type: msvc"
OBJSUFFIX    := obj
LIBSUFFIX    := lib
DLLSUFFIX    := dll
EXE          := .exe
else
OBJSUFFIX    := o
LIBSUFFIX    := a
ifeq "$(findstring mingw,$(shell $(OCAMLC) -config |grep system))" "mingw"
DLLSUFFIX    := dll
EXE          := .exe
else
DLLSUFFIX    := so
EXE          :=
endif
endif


# project files
###############

CSRC = caml_z.c
MLSRC = zarith_version.ml z.ml q.ml big_int_Z.ml
MLISRC = z.mli q.mli big_int_Z.mli

AUTOGEN = zarith_version.ml

CMIOBJ = $(MLISRC:%.mli=%.cmi)
CMXOBJ = $(MLISRC:%.mli=%.cmx)
CMIDOC = $(MLISRC:%.mli=%.cmti)

TOBUILD = zarith.cma libzarith.$(LIBSUFFIX) $(CMIOBJ) zarith_top.cma z.mli

TOINSTALL = $(TOBUILD) zarith.h q.mli big_int_Z.mli

ifeq ($(HASOCAMLOPT),yes)
TOBUILD += zarith.cmxa $(CMXOBJ)
TOINSTALL += zarith.$(LIBSUFFIX)
endif
DEBUG = -g
OCAMLFLAGS += $(DEBUG) -I +compiler-libs
OCAMLOPTFLAGS += $(DEBUG) -I +compiler-libs

ifeq ($(HASDYNLINK),yes)
TOBUILD += zarith.cmxs
endif

ifeq ($(HASBINANNOT),yes)
TOINSTALL += $(CMIDOC)
OCAMLFLAGS += -bin-annot
endif

MKLIBLDFLAGS = $(foreach flag, $(LDFLAGS), -ldopt $(flag))

# build targets
###############

all: $(TOBUILD)

tests:
	make -C tests test

zarith.cma: $(MLSRC:%.ml=%.cmo)
	$(OCAMLMKLIB) $(DEBUG) -failsafe -o zarith $+ $(LIBS) $(MKLIBLDFLAGS)

zarith.cmxa: $(MLSRC:%.ml=%.cmx)
	$(OCAMLMKLIB) $(DEBUG) -failsafe -o zarith $+ $(LIBS) $(MKLIBLDFLAGS)

zarith.cmxs: zarith.cmxa libzarith.$(LIBSUFFIX)
	$(OCAMLOPT) -shared -o $@ -I . zarith.cmxa -linkall

libzarith.$(LIBSUFFIX): $(CSRC:%.c=%.$(OBJSUFFIX))
	$(OCAMLMKLIB) $(DEBUG) -failsafe -o zarith $+ $(LIBS) $(MKLIBLDFLAGS)

zarith_top.cma: zarith_top.cmo
	$(OCAMLC) $(DEBUG) -o $@ -a $<

doc: $(MLISRC)
ifneq ($(OCAMLDOC),)
	mkdir -p html
	$(OCAMLDOC) -html -d html -charset utf8 $+
else
	$(error ocamldoc is required to build the documentation)
endif

zarith_version.ml: META
	(echo "let"; grep "version" META | head -1) > zarith_version.ml

# install targets
#################

ifeq ($(INSTMETH),install)
install:
	install -d $(INSTALLDIR) $(INSTALLDIR)/zarith $(INSTALLDIR)/stublibs
	for i in $(TOINSTALL); do \
		if test -f $$i; then $(INSTALL) -m 0644 $$i $(INSTALLDIR)/zarith/$$i; fi; \
	done
	if test -f dllzarith.$(DLLSUFFIX); then $(INSTALL) -m 0755 dllzarith.$(DLLSUFFIX) $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); fi

uninstall:
	for i in $(TOINSTALL); do \
		rm -f $(INSTALLDIR)/zarith/$$i; \
	done
	if test -f $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); then rm -f $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); fi
endif

ifeq ($(INSTMETH),findlib)
install:
	$(OCAMLFIND) install -destdir "$(INSTALLDIR)" zarith META $(TOINSTALL) -optional dllzarith.$(DLLSUFFIX)

uninstall:
	$(OCAMLFIND) remove -destdir "$(INSTALLDIR)" zarith
endif


# rules
#######

%.cmi: %.mli
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmo: %.ml %.cmi
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmx: %.ml %.cmi
	$(OCAMLOPT) $(OCAMLOPTFLAGS) $(OCAMLINC) -c $<

%.cmo: %.ml
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(OCAMLOPTFLAGS) $(OCAMLINC) -c $<

%.$(OBJSUFFIX): %.c
	$(OCAMLC) -ccopt "$(CFLAGS)" -c $<

clean:
	/bin/rm -rf *.$(OBJSUFFIX) *.$(LIBSUFFIX) *.$(DLLSUFFIX) *.cmi *.cmo *.cmx *.cmxa *.cmxs *.cma  *.cmt *.cmti *~ \#* depend test $(AUTOGEN) tmp.c depend
	make -C tests clean

depend: $(AUTOGEN)
	$(OCAMLDEP) -native $(OCAMLINC) $(MLSRC) $(MLISRC) > depend

include depend

$(CSRC:%.c=%.$(OBJSUFFIX)): zarith.h

.PHONY: clean
.PHONY: tests
