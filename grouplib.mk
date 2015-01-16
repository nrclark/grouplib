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
$(eval __sg_RESPONSE := $(shell mkdir -p $(1)))\
$(eval $(if $(__sg_RESPONSE),$(error $(__sg_RESPONSE)),))\
$(eval GROUPLIB_TEMPDIR := $(1))

#------------------------ GNU Make Version Checker ----------------------------#
# Grouplib.mk works with version 3.82 of Make or higher. This checker
# enforces the version.

__sg_gMAJOR := $(wordlist 1,1,$(subst ., ,$(MAKE_VERSION)))
__sg_gMINOR := $(wordlist 2,2,$(subst ., ,$(MAKE_VERSION)))
ifeq (0,$(shell test $(__sg_gMAJOR) -ge 4; echo $$?))
__sg_gVERSION_OK := YES
endif
ifeq (0,$(shell test $(__sg_gMAJOR) -eq 3; echo $$?))
ifeq (0,$(shell test $(__sg_gMINOR) -eq 82; echo $$?))
__sg_gVERSION_OK := YES
endif
endif
ifneq ($(__sg_gVERSION_OK),YES)
$(warning GNU Make version 3.82 or higher is required)
$(error (version [$(__sg_gMAJOR).$(__sg_gMINOR)] detected))
endif

#------------------------------------------------------------------------------#

# Variable that holds the current group name. Note that __sg_GROUP will change
# with each call to __sg_next_group.

__sg_GROUP := __sg_GROUP_0000

# Numerical macros used by __sg_next_group for counting from __sg_GROUP_0000 to
# __sg_GROUP_9999. __sg_NUMBERS winds up containing the list 0002...9999.

__sg_COUNTER := 0001
__sg_DIGITS := 0 1 2 3 4 5 6 7 8 9
__sg_NUMBERS := \
$(foreach a,$(__sg_DIGITS),\
$(foreach b,$(__sg_DIGITS),\
$(foreach c,$(__sg_DIGITS),\
$(foreach d,$(__sg_DIGITS),\
$(a)$(b)$(c)$(d)))))
__sg_NUMBERS := $(wordlist 3,99999,$(__sg_NUMBERS))

# Increments __sg_GROUP using the __sg_COUNTER and __sg_NUMBERS macros from above.
define __sg_next_group =
__sg_GROUP := __sg_GROUP_$(__sg_COUNTER)
__sg_COUNTER := $(word $(__sg_COUNTER),$(__sg_NUMBERS))
endef

# Macros for space, tab, and newline. Used in creating recipes.
__sg_blank :=
__sg_space := $(__sg_blank) $(__sg_blank)
__sg_tab := $(__sg_blank)	$(__sg_blank)
__sg_dollar := $$
define __sg_newline


endef

# Name of the temporary Makefile used by __sg_update_needed. Note that
# this macro depends on __sg_GROUP, so it will change with each call to
# __sg_next_group.

__sg_makefile = $(GROUPLIB_TEMPDIR)/$(__sg_GROUP)_UMAKEFILE

# Returns an empty string if the list of targets in $(2) is current
# with respect to the list of dependencies in $(1). Under any other circumstances,
# the returned string is non-empty.

__sg_update_needed = \
$(strip $(subst 0,,$(shell \
printf "default: $(2)\n\n" > $(call __sg_makefile);\
printf "$(2): $(1)\n\techo OLD\n" >> $(call __sg_makefile);\
MAKEFLAGS="" MFLAGS="" GNUMAKEFLAGS="" \
$(MAKE) --no-print-directory -q -f $(call __sg_makefile) 2>&1;\
RES=$$?;\
$(RM) $(call __sg_makefile);\
printf $$RES;)))

# Used by __sg_remove_spaces/__sg_restore_spaces.

__sg_wordsep := @^&~!@^^@~~^!@

# Removes all spaces from a list, by replacing them with the separator sequence.

__sg_remove_spaces = $(subst $(__sg_space),$(__sg_wordsep),$(1))

# Restores the spaces to a list that has had them replaced by __sg_remove_spaces.

__sg_restore_spaces = $(subst $(__sg_wordsep),$(__sg_space),$(1))

# Returns a list of the targets from a string of the general form 
# 'target1 target2: dep1 dep2'. So running
# $(call __sg_get_targets,foo bar baz: input ofus) will return the list
# input ofus.

__sg_get_targets = \
$(strip $(call __sg_restore_spaces,$(word 1,$(subst :,$(__sg_space),\
$(call __sg_remove_spaces,$(1))))))

# Returns a list of the dependencies from a string of the general form 
# 'target1 target2: dep1 dep2'. So running
# $(call __sg_get_targets,foo bar baz: input ofus) will return the list
# foo bar baz.

__sg_get_depends = \
$(strip $(call __sg_restore_spaces,$(word 2,$(subst :,$(__sg_space),\
$(call __sg_remove_spaces,$(1))))))

# Macro that generates one of two recipes. If $(2) is fresh with respect
# to $(1), the recipe generated is:
# 
# GROUP.sentinel:
#     $(eval $(file >GROUP.sentinel,))
#
# If $(2) is stale with respect to $(1), the following recipe is generated
# instead:
#
# GROUP.sentinel: GROUP_PHONY
#     $(eval $(file >GROUP.sentinel,))
#
__sg_sentinel_recipe = $(__sg_GROUP).sentinel: $(if $(call __sg_update_needed,$(1),$(2)),$(__sg_GROUP)_PHONY,)$(__sg_newline)$(__sg_tab)$(__sg_dollar)(eval $(__sg_dollar)(file >$(__sg_GROUP).sentinel,))$(__sg_newline)$(__sg_newline)

# Macro to generate the target's actual recipe. Generated recipes are of
# the form:
#
# out1 out2: GROUP.sentinel
#   $(eval $(foreach x,out1 out2,$(if $(wildcard $(x)),,$(error error: $(x) was not created))))
#   @$(RM) GROUP.sentinel

__sg_assert_exists = $(foreach x,$(1),$(if $(wildcard $(x)),,$(error error: $(x) was not created)))
__sg_target_recipe = $(2): $(1) $(__sg_GROUP).sentinel$(__sg_newline)$(__sg_tab)$(__sg_dollar)(eval $(__sg_dollar)(call __sg_assert_exists,$(2)))$(__sg_newline)$(__sg_tab)@$(RM) $(__sg_GROUP).sentinel$(__sg_newline)$(__sg_newline)

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
$(eval $(call __sg_next_group))\
$(eval __sg_TARGETS := $(call __sg_get_targets,$(1)))\
$(eval __sg_DEPENDS := $(call __sg_get_depends,$(1)))\
$(eval $(call __sg_target_recipe,$(__sg_DEPENDS),$(__sg_TARGETS)))\
$(eval $(call __sg_sentinel_recipe,$(__sg_DEPENDS),$(__sg_TARGETS)))\
$(eval .INTERMEDIATE: $(call __sg_makefile) $(__sg_GROUP).sentinel$(__sg_newline)$(__sg_newline))\
$(eval .PHONY: $(__sg_GROUP)_PHONY$(__sg_newline)$(__sg_newline))\
$(__sg_GROUP)_PHONY: $(__sg_DEPENDS)
