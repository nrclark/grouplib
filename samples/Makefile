include ../grouplib.mk

TASK1_SRCS = foo bar
TASK1_OUTPUTS = baz bob

default: both both2

demo:
	echo $(call sort_floats,1.11 10.11 2.11 21.11 0.11 0.01 0.1)
	echo $(call get_mtime,foo)

$(call group_create,task1,$(TASK1_SRCS),$(TASK1_OUTPUTS))

$(call group_target,task1): $(call group_deps,task1)
	echo 'running task "task 1"'
	sleep 2
	touch $(TASK1_OUTPUTS)

#----------------------------------------------------#

debug:
	echo rm -f $(call group_intermediates)
	$(eval x := task1)
	$(eval y := $(TASK1_SRCS))
	$(eval z := $(TASK1_OUTPUTS))
	echo $(x) [$(z): $(y)]
	echo "[$(call outdated,$(y),$(z))]"
#echo $(call _ssentinel,$(x)): $(if $(call _supdate_needed,$(y),$(z)),$(call _sphony,$(x)),)
#echo $(call _supdate_needed,$(y),$(z))
#echo $(call group_target,task1): $(call group_deps,task1)

both2: $(TASK1_OUTPUTS)
	echo 'running task "both2"'
	$(foreach x,$^,test -e $(x) &&) echo;
	sleep 4
	touch both2

both: $(TASK1_OUTPUTS)
	echo 'running task "both"'
	$(foreach x,$^,test -e $(x) &&) echo;
	sleep 4
	touch both

task2: baz
	echo 'running task "task 2", depending on task 1'

task3: bob
	echo 'running task "task 3", depending on task 1'

clean:
	@rm -f $(call group_get_intermediates)
	rm -f baz bob
	rm -f both both2

.INTERMEDIATE: $(call group_get_intermediates)

.PHONY: _SPHONY_GLOBAL $(call group_get_phonies)
.SUFFIXES: 
