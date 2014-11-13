include ../experimental.mk

TASK1_SRCS = foo bar
TASK1_OUTPUTS = baz bob

default: both

#---------------------------------------------------------------------#

mtime_cmd = $(shell perl -WE \
'use Time::HiRes qw( stat lstat );\
@a = stat("$(1)");\
print $$a[9];')

fsort = $(shell perl -WE \
'@x = ($(foreach x,$(1),$(x),));\
@x = sort { $$a <=> $$b } @x;\
print "@x";')

leq = $(shell perl -WE 'print $(1) > $(2) ? 0 : 1 ;')

mtime = $(if $(wildcard $(1)),$(call mtime_cmd,$(realpath $(1))),0)
missing = $(strip $(foreach x,$(1),$(if $(wildcard $(x)),,$(x))))
newest_mtime = \
$(lastword $(call sort,$(foreach x,$(1),$(call mtime,$(x)))))
oldest_mtime = \
$(firstword $(call sort,$(foreach x,$(1),$(call mtime,$(x)))))
ismaller = $(subst 0,,$(call leq,$(1),$(2)))

old_target = $(if \
$(call ismaller,$(call oldest_mtime,$(2)),$(call newest_mtime,$(1))),\
OLD,)

update_needed = \
$(strip $(call old_target,$(1),$(2))$(call missing,$(1) $(2)))

#--------------------------------------------------------------------#

GLOBAL_PHONY:

define \n


endef

baz bob: task1.sentinel
	$(foreach x,$@,@test -e $(x)$(\n))

task1.sentinel: $(if $(call update_needed,foo bar,baz bob),TASK1_PHONY,)
	touch task1.sentinel

TASK1_PHONY: foo bar
	echo 'running task "task 1"'
	sleep 2
	touch baz bob

#----------------------------------------------------#

both: $(TASK1_OUTPUTS)
	$(foreach x,$^,test -e $(x) &&) echo;
	echo 'running task "both"'
	sleep 4
	touch both

task2: baz
	echo 'running task "task 2", depending on task 1'

task3: bob
	echo 'running task "task 3", depending on task 1'

clean:
	rm -f task1.sentinel
	rm -f baz bob
	rm -f both

.INTERMEDIATE: task1.sentinel
.PHONY: PHONY_GLOBAL $(call group_get_phonies)
.SUFFIXES: 
