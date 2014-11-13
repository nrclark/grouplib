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

#-------------------------- Perl Version Checker ------------------------------#

ifneq (0,\
$(strip $(lastword $(shell which perl; echo " "$$?))))
$(error perl not detected on this system)
endif

ifneq (0,\
$(lastword $(shell perl -WE 'use Time::HiRes qw( stat lstat )'; echo " "$$?)))
$(error HiRes module not detected on the system installation of Perl)
endif

# This function uses Perl to get the mtime and print it. It uses a Perl to gain
# access to the high-precision mtime that Perl provides (a standard "stat"
# generally only shows the granularity in seconds).
 
_smtime_cmd = $(shell perl -WE \
'use Time::HiRes qw( stat lstat );\
@a = stat("$(1)");\
print $$a[9];')

# This function uses Perl to sort a list of floats.
_ssort = $(shell perl -WE \
'@x = ($(foreach x,$(1),$(x),));\
@x = sort { $$a <=> $$b } @x;\
print "@x";')

# This function uses Perl to do a less-than/equal-to comparison.
_sleq = $(shell perl -WE 'print $(1) > $(2) ? 0 : 1 ;')

#------------------------------------------------------------------------------#

# These variables are used internally. The sentinel storage directory
# can also be manually set through the use of group_setdir, if the
# default (.sentinels) isn't acceptable in your build.

_SENTINEL_DIR := .
_GROUP_LIST :=
_SPHONY_DEFINED := NO

define _snewline


endef

_ssentinel = $(_SENTINEL_DIR)/_$(1).sentinel
_sphony = _GROUP_$(1)_PHONY
_sdepends_name = _GROUP_$(1)_DEPENDS
_soutputs_name = _GROUP_$(1)_OUTPUTS
_sdepends = $(value $(call _sdepends_name,$(1)))
_soutputs = $(value $(call _soutputs_name,$(1)))

_smtime = $(if $(wildcard $(1)),$(call _smtime_cmd,$(realpath $(1))),0)
_smissing = $(strip $(foreach x,$(1),$(if $(wildcard $(x)),,$(x))))
_snewest_mtime = \
$(lastword $(call _ssort,$(foreach x,$(1),$(call _smtime,$(x)))))
_soldest_mtime = \
$(firstword $(call _ssort,$(foreach x,$(1),$(call _smtime,$(x)))))
_sis_smaller = $(subst 0,,$(call _sleq,$(1),$(2)))

_sold_target = $(if \
$(call _sis_smaller,$(call _soldest_mtime,$(2)),$(call _snewest_mtime,$(1))),\
OLD,)

_supdate_needed = \
$(strip $(call _sold_target,$(1),$(2))$(call _smissing,$(1) $(2)))

define _smkgroup_code =
$(if $(filter $(1),$(_GROUP_LIST)),$(error group '$(1)' is already defined),)
$(if $(3),,$(error group '$(1)' outputs not defined))
$(if $(2),,$(warning group '$(1)' sources not defined))
$(if $(1),,$(error group-name not provided for $(3)))
ifeq (NO,$(_SPHONY_DEFINED))
_SPHONY_DEFINED := YES
_SPHONY_GLOBAL:

endif
_GROUP_LIST := $(strip $(_GROUP_LIST) $(1))
$(call _sdepends_name,$(1)) := $(2)
$(call _soutputs_name,$(1)) := $(3)

$(3): $(call _ssentinel,$(1))
	$(foreach x,$@,@test -e $(x)$(_snewline))

$(call _ssentinel,$(1)): $(if $(call _supdate_needed,$(2),$(3)),$(call _sphony,$(1)),)
	@touch $(call _ssentinel,$(1))

endef

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
group_intermediates = $(call group_get_sentinels)
