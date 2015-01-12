# Grouplib, version 3! Now with 50% more elegance.
# And with 100% more unreadability.
#
# Use it like this:
#
# Convert this:
#
#     out1 out2: in1 in2
#         your_recipe;
#
# to:
#
#     include grouplib_v3.mk
#     
#     $(call group, out1 out2: in1 in2)
#          cat in1 > out1
#          cat in2 > out2
#
# That's it!
# Oh - Grouplib needs to create some temporary files that it cleans up automatically.
# By default these files are created in the current working directory ('.'). 
#
# If you would like these files to live somewhere else, use $(call set_grouplib_dir,YOUR_PATH)
# before making your first group.

GROUPLIB_TEMPDIR := .

# Function that sets Grouplib's operating directory. Grouplib might eventually
# move to a directory-free system, but creates (and deletes) temporary files
# in the mean-time.

set_grouplib_dir = \
$(eval _sRESPONSE := $(shell mkdir -p $(1)))\
$(eval $(if $(_sRESPONSE),$(error $(_sRESPONSE)),))\
$(eval GROUPLIB_TEMPDIR := $(1))

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

# Variable that holds the current group name. Note that _sGROUP will change
# with each call to _snext_group.

_sGROUP := _sGROUP_0000

# Numerical macros used by _snext_group for counting from _sGROUP_0000 to
# _sGROUP_9999. _sNUMBERS winds up containing the list 0002...9999.

_sCOUNTER := 0001
_sDIGITS := 0 1 2 3 4 5 6 7 8 9
_sNUMBERS := \
$(foreach a,$(_sDIGITS),\
$(foreach b,$(_sDIGITS),\
$(foreach c,$(_sDIGITS),\
$(foreach d,$(_sDIGITS),\
$(a)$(b)$(c)$(d)))))
_sNUMBERS := $(wordlist 3,99999,$(_sNUMBERS))

# Increments _sGROUP using the _sCOUNTER and _sNUMBERS macros from above.
define _snext_group =
_sGROUP := _sGROUP_$(_sCOUNTER)
_sCOUNTER := $(word $(_sCOUNTER),$(_sNUMBERS))
endef

# Macros for space, tab, and newline. Used in creating recipes.
_sblank :=
_sspace := $(_sblank) $(_sblank)
_stab := $(_sblank)	$(_sblank)
define _snewline


endef

# Name of the temporary Makefile used by _supdate_needed. Note that
# this macro depends on _sGROUP, so it will change with each call to
# _snext_group.

_smakefile = $(GROUPLIB_TEMPDIR)/$(_sGROUP)_UMAKEFILE

# Returns an empty string if the list of targets in $(2) is current
# with respect to the list of dependencies in $(1). Under any other circumstances,
# the returned string is non-empty.

_supdate_needed = \
$(strip $(subst 0,,$(shell \
printf "default: $(2)\n\n" > $(call _smakefile);\
printf "$(2): $(1)\n\techo OLD\n" >> $(call _smakefile);\
MAKEFLAGS="" MFLAGS="" GNUMAKEFLAGS="" \
$(MAKE) --no-print-directory -q -f $(call _smakefile) 2>&1;\
RES=$$?;\
$(RM) $(call _smakefile);\
printf $$RES;)))

# Used by _sremove_spaces/_srestore_spaces.

_swordsep := @^&~!@^^@~~^!@

# Removes all spaces from a list, by replacing them with the separator sequence.

_sremove_spaces = $(subst $(_sspace),$(_swordsep),$(1))

# Restores the spaces to a list that has had them replaced by _sremove_spaces.

_srestore_spaces = $(subst $(_swordsep),$(_sspace),$(1))

# Returns a list of the targets from a string of the general form 
# 'target1 target2: dep1 dep2'. So running
# $(call _sget_targets,foo bar baz: input ofus) will return the list
# input ofus.

_sget_targets = \
$(strip $(call _srestore_spaces,$(word 1,$(subst :,$(_sspace),\
$(call _sremove_spaces,$(1))))))

# Returns a list of the dependencies from a string of the general form 
# 'target1 target2: dep1 dep2'. So running
# $(call _sget_targets,foo bar baz: input ofus) will return the list
# foo bar baz.

_sget_depends = \
$(strip $(call _srestore_spaces,$(word 2,$(subst :,$(_sspace),\
$(call _sremove_spaces,$(1))))))

# Macro that generates one of two recipes. If $(2) is fresh with respect
# to $(1), the recipe generated is:
# 
# GROUP.sentinel:
#     touch GROUP.sentinel
#
# If $(2) is stale with respect to $(1), the following recipe is generated
# instead:
#
# GROUP.sentinel: GROUP_PHONY
#     touch GROUP.sentinel
#
_ssentinel_recipe = $(_sGROUP).sentinel: $(if $(call _supdate_needed,$(1),$(2)),$(_sGROUP)_PHONY,)$(_snewline)$(_stab)@touch $(_sGROUP).sentinel$(_snewline)$(_snewline)

# Macro to generate the target's actual recipe. Generated recipes are of
# the form:
#
# out1 out2: GROUP.sentinel
# 	@test -e out1 && test -e out2 && printf
#   @rm -f GROUP.sentinel

_starget_recipe = $(1): $(_sGROUP).sentinel$(_snewline)$(_stab)@$(foreach x,$(1),test -e $(x) &&) printf ''$(_snewline)$(_stab)@rm -f $(_sGROUP).sentinel$(_snewline)$(_snewline)

# Function that generates all required code to create a build-group.
# The build-group is automatically named, and the name is auto-incremented.
# A small recipe is created for the group's targets which links them
# to the group's internal sentinel file. 
#
# The sentinel recipe is then created with a conditional dependence on the group's
# phony (depending on whether the group's targets are fresh with respect to their
# dependencies). Finally, the group's phony recipe is delared, but not filled in.
# This is where the macro stops, and then user's normal recipe attaches to the
# phony.

group = \
$(eval $(call _snext_group))\
$(eval _sTARGETS := $(call _sget_targets,$(1)))\
$(eval _sDEPENDS := $(call _sget_depends,$(1)))\
$(eval $(call _starget_recipe,$(_sTARGETS)))\
$(eval $(call _ssentinel_recipe,$(_sDEPENDS),$(_sTARGETS)))\
$(eval .INTERMEDIATE: $(call _smakefile) $(_sGROUP).sentinel$(_snewline)$(_snewline))\
$(eval .PHONY: $(_sGROUP)_PHONY$(_snewline)$(_snewline))\
$(_sGROUP)_PHONY: $(_sDEPENDS)
