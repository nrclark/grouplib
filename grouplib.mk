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
##----------------------- GNU Make Version Checker ---------------------------#

# Grouplib.mk works with version 3.82 of Make or higher. This checker
# enforces the version.

_MVER := $(MAKE_VERSION)
_MVER := $(subst ., ,$(_MVER))
_MVER := $(wordlist 1,2,$(_MVER))
_MAJOR := $(wordlist 1,1,$(_MVER))
_MINOR := $(wordlist 2,2,$(_MVER))

_VERSION_OK := NO
ifeq (0,$(shell test $(_MAJOR) -ge 4; echo $$?))
_VERSION_OK := YES
endif
ifeq (0,$(shell test $(_MAJOR) -eq 3; echo $$?))
ifeq (0,$(shell test $(_MINOR) -eq 82; echo $$?))
_VERSION_OK := YES
endif
endif
ifeq (NO,$(_VERSION_OK))
$(error GNU Make version 3.82 or higher is required)
endif

#------------------------------------------------------------------------#

# These variables are used internally. The sentinel storage directory
# can also be manually set through the use of group_setdir, if the
# default (.sentinels) isn't acceptable in your build.

_SENTINEL_DIR := .sentinels
_SENTINEL_LIST :=

# _smissing accepts a list of input filenames, and returns a list of
# any files that are missing (or an empty string otherwise)

_smissing = $(strip $(foreach x,$(1),$(if $(wildcard $(x)),,$(x))))

_ssentinel_name = $(_SENTINEL_DIR)/_$(1).sentinel
_sdepends_name = _GROUP_$(1)_DEPENDS
_soutputs_name = _GROUP_$(1)_OUTPUTS
_sphony = _GROUP_$(1)_PHONY
_sdepends = $(value $(call _sdepends_name,$(1)))
_soutputs = $(value $(call _soutputs_name,$(1)))
_sverify = $(if $(call _smissing,$(call _soutputs,$(1))),$(call _sphony,$(1)),)

define _smkgroup_code =
$(if $(filter $(1),$(_SENTINEL_LIST)),$(error group '$(1)' is already defined),)
_SENTINEL_LIST := $(strip $(_SENTINEL_LIST) $(1))
$(if $(3),,$(error group '$(1)' outputs not defined))
$(if $(2),,$(warning group '$(1)' sources not defined))
$(if $(1),,$(error group-name not provided for $(3)))
$(3): $(call _ssentinel_name,$(1))
$(call _sphony,$(1)):

$(call _sdepends_name,$(1)) := $(2)
$(call _soutputs_name,$(1)) := $(3)
endef

define _sgroup_finish =
@mkdir -p $(_SENTINEL_DIR)
@touch $(call _ssentinel_name,$(1))
endef

group_create = $(eval $(call _smkgroup_code,$(1),$(2),$(3)))
group = $(call _ssentinel_name,$(1))
group_deps = $(call _sdepends,$(1)) $(call _sverify,$(1))
group_finish = $(call _sgroup_finish,$(1))

group_outputs = $(call _soutputs,$(1))
group_sentinel = $(call _ssentinel_name,$(1))

group_all_sentinels = $(_SENTINEL_LIST)
group_getdir = $(_SENTINEL_DIR)
group_setdir = $(eval _SENTINEL_DIR := $(1))
group_get_phonies = $(foreach x,$(_SENTINEL_LIST),$(call _sphony,$(x)))
