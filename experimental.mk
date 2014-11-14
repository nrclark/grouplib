#--------------- Grouplib: GNU Make Grouped-Target Library --------------------#
#
# Written by Nicholas Clark on 13-November-2014.
# Released under the terms of the GNU General Public License version 2.
#
# Grouplib is a pure GNU Make library that provides a set of user functions
# (which can be called with GNU Make's 'call' command) for managing 
# multi-target recipes. It uses auto-generated (and auto-deleted) sentinel
# files along with a little bit of magic to provide parallel-safe grouped
# outputs.
#
# Quick Refererence
# -----------------
#
# Normal use cases:
#
# $(call group_create,groupname,group_deps,group_outputs)
# $(call group_target,groupname)
# $(call group_deps,groupname)
# 
# $(call group_get_intermediates)
# $(call group_get_phonies)
#
# Advanced use cases:
#
# $(call group_outputs,groupname)
# $(call group_sentinel,groupname) 
# $(call group_get_sentinels)
# $(call group_getdir)
# $(call group_setdir,dirname)
#
# Sample use:
#
#     $(call group_create,frobnicate,foo bar, baz bob)
#     $(call group_target,frobnicate): $(call group_deps, frobnicate)
#         cat foo bar > baz
#         touch bob
#
#     corral: baz bob
#	      touch corral
#
#     .INTERMEDIATE: $(call group_get_intermediates)
#     .PHONY: $(call group_get_phonies)
#
#------------------------ GNU Make Version Checker ----------------------------#

# Grouplib.mk works with version 3.82 of Make or higher. This checker
# enforces the version.

_sgMAJOR := $(wordlist 1,1,$(subst ., ,$(MAKE_VERSION)))
_sgMINOR := $(wordlist 2,2,$(subst ., ,$(MAKE_VERSION)))

ifeq (0,$(shell test $(_sgMAJOR) -ge 4; echo $$?))
_sgVERSION_OK := YES
endif
ifeq (0,$(shell test $(_sgMAJOR) -eq 3; echo $$?))
ifeq (0,$(shell test $(_sgMINOR) -eq 82; echo $$?))
_sgVERSION_OK := YES
endif
endif
ifneq ($(_sgVERSION_OK),YES)
$(warning GNU Make version 3.82 or higher is required)
$(error (version [$(_sgMAJOR).$(_sgMINOR)] detected))
endif

#------------------------------------------------------------------------------#

# These variables are used internally. The sentinel storage directory
# can also be manually set through the use of group_setdir, if the
# default (.sentinels) isn't acceptable in your build.

_sSENTINEL_DIR := .
_sGROUP_LIST :=

#---------------------------- Freshness Checker -------------------------------#

# This routine is used to determine the freshness of a set of targets
# in a sandbox environment. It is used within Grouplib to tell
# internal targets when they need to be updated.
#
# It works by generating a small dummy Makefile, feeding it to Make, and
# checking to see whether the targets are stale or not (returned via
# the response from 'make -q').

_supdate_needed = $(strip $(subst 0,,$(shell \
printf "default: $(2)\n\n" > $(call _smakefile);\
printf "$(2): $(1)\n\techo OLD\n" >> $(call _smakefile);\
MAKEFLAGS="" MFLAGS="" GNUMAKEFLAGS="" \
$(MAKE) --no-print-directory -q -f $(call _smakefile) 2>&1;\
RES=$$?;\
rm -f $(call _smakefile);\
echo $$RES;)))

#------------------------------ Other Commands --------------------------------#

_ssentinel = $(_sSENTINEL_DIR)/_$(1).sentinel
_smakefile = $(call _ssentinel,_smakefile).mk
_sphony = _sGROUP_$(1)_PHONY
_sdepends_name = _sGROUP_$(1)_DEPENDS
_soutputs_name = _sGROUP_$(1)_OUTPUTS
_sdepends = $(value $(call _sdepends_name,$(1)))
_soutputs = $(value $(call _soutputs_name,$(1)))

define _smkgroup_code =
$(if $(filter $(1),$(_sGROUP_LIST)),$(error group '$(1)' is already defined),)
$(if $(3),,$(error group '$(1)' outputs not defined))
$(if $(2),,$(warning group '$(1)' sources not defined))
$(if $(1),,$(error group-name not provided for $(3)))
_SRESULT :=  $(shell rm -f $(call _ssentinel,$(1)))
_sGROUP_LIST := $(strip $(_sGROUP_LIST) $(1))
$(call _sdepends_name,$(1)) := $(2)
$(call _soutputs_name,$(1)) := $(3)

$(3): $(call _ssentinel,$(1))
	@$(foreach x,$(3),test -e $(x) &&) printf '';
	@rm -f $(call _ssentinel,$(1))

$(call _ssentinel,$(1)): \
$(if $(call _supdate_needed,$(2),$(3)),$(call _sphony,$(1)),)
	@touch $(call _ssentinel,$(1))

endef

#--------------------------- User-Facing Commands -----------------------------#

group_create = $(eval $(call _smkgroup_code,$(1),$(2),$(3)))
group_deps = $(call _sdepends,$(1))
group_target = $(call _sphony,$(1))

group_outputs = $(call _soutputs,$(1))
group_sentinel = $(call _ssentinel,$(1))

group_get_intermediates = $(call group_get_sentinels) $(call _smakefile)
group_get_phonies = $(foreach x,$(_sGROUP_LIST),$(call _sphony,$(x)))

group_get_sentinels = $(foreach x,$(_sGROUP_LIST),$(call _ssentinel,$(x)))
group_getdir = $(_sSENTINEL_DIR)
group_setdir = $(eval _sSENTINEL_DIR := $(1))
