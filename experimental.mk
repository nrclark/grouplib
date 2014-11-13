#--------------- Grouplib: GNU Make Grouped-Target Library --------------------#
#
# Written by Nicholas Clark on 11-November-2014.
# Released under the terms of the GNU General Public License version 2.
#
# Grouplib is a pure GNU Make library that provides a set of user functions
# (which can be called with GNU Make's 'call' command) for managing 
# multi-target recipes.
#
# Quick Refererence
#
# Normal use cases:
#
# $(call group_create,groupname,group_deps,group_outputs)
# $(call group,groupname)
# $(call group_deps,groupname)
# $(call group_finish,groupname)
# 
# Advanced use cases:
#
# $(call group_outputs,groupname)
# $(call group_sentinel,groupname) 
# $(call group_all_sentinels)
# $(call group_getdir)
# $(call group_setdir,dirname)
# $(call group_get_phonies)
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

_SENTINEL_DIR := .
_GROUP_LIST :=

define _snewline


endef

#---------------------------- Freshness Checker -------------------------------#

# This routine is used to determine the freshness of a set of targets
# in a sandbox environment. It is used within Grouplib to tell
# internal targets when they need to be updated.
#
# It works by generating a small dummy Makefile, feeding it to Make, and
# checking to see whether the targets are stale or not (returned via
# the response from Make -q).

_supdate_needed = $(strip $(subst 0,,$(shell \
printf "default: $(2)\n\n" > $(_SENTINEL_DIR)/_sentinel.makefile.temp;\
printf "$(2): $(1)\n\techo OLD\n" >> $(_SENTINEL_DIR)/_sentinel.makefile.temp;\
MAKEFLAGS="" MFLAGS="" GNUMAKEFLAGS="" \
$(MAKE) --no-print-directory -q \
-f $(_SENTINEL_DIR)/_sentinel.makefile.temp 2>&1;\
RES=$$?;\
rm -f $(_SENTINEL_DIR)/_sentinel.makefile.temp;\
echo $$RES;)))

#------------------------------ Other Commands --------------------------------#

_ssentinel = $(_SENTINEL_DIR)/_$(1).sentinel
_sphony = _GROUP_$(1)_PHONY
_sdepends_name = _GROUP_$(1)_DEPENDS
_soutputs_name = _GROUP_$(1)_OUTPUTS
_sdepends = $(value $(call _sdepends_name,$(1)))
_soutputs = $(value $(call _soutputs_name,$(1)))

define _smkgroup_code =
$(if $(filter $(1),$(_GROUP_LIST)),$(error group '$(1)' is already defined),)
$(if $(3),,$(error group '$(1)' outputs not defined))
$(if $(2),,$(warning group '$(1)' sources not defined))
$(if $(1),,$(error group-name not provided for $(3)))
_GROUP_LIST := $(strip $(_GROUP_LIST) $(1))
$(call _sdepends_name,$(1)) := $(2)
$(call _soutputs_name,$(1)) := $(3)

$(3): $(call _ssentinel,$(1))
	@$(foreach x,$(3),test -e $(x) &&) printf '';

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

group_all_sentinels = $(foreach x,$(_GROUP_LIST),$(call _ssentinel,$(x)))
group_getdir = $(_SENTINEL_DIR)
group_setdir = $(eval _SENTINEL_DIR := $(1))
group_get_phonies = $(foreach x,$(_GROUP_LIST),$(call _sphony,$(x)))
group_get_sentinels = $(foreach x,$(_GROUP_LIST),$(call _ssentinel,$(x)))
group_intermediates = $(call group_get_sentinels) \
$(_SENTINEL_DIR)/_sentinel.makefile.temp
