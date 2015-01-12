include ../grouplib.mk

TASK1_SRCS = foo bar
TASK1_OUTPUTS = baz bob

default: both both2

$(call group,$(TASK1_OUTPUTS): $(TASK1_SRCS))
	echo 'running task "task 1"'
	sleep 2
	touch $(TASK1_OUTPUTS)

#----------------------------------------------------#

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

.PHONY: clean task2 task3
.SUFFIXES: 
