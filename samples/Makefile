include ../grouplib.mk
$(call group_setdir,_sentinels)

TASK1_SRCS = foo bar
TASK1_OUTPUTS = baz bob

default: both

$(call group_create,task1,$(TASK1_SRCS),$(TASK1_OUTPUTS))

test:
	echo $(MAKE_VERSION)
	echo $(call group,task1): $(call group_deps,task1)
	echo $(call group_get_phonies)

$(call group,task1): $(call group_deps,task1)
	echo 'running task "task 1"'
	sleep 0.25
	touch $(TASK1_OUTPUTS)
	$(call group_finish,task1)

both: $(TASK1_OUTPUTS)
	$(foreach x,$^,test -e $(x) &&) echo;
	echo 'running task "both"'

task2: baz
	echo 'running task "task 2", depending on task 1'

task3: bob
	echo 'running task "task 3", depending on task 1'

clean:
	rm -f baz bob
	rm -rf $(call group_getdir)
