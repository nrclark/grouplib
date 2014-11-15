include ../grouplib.mk

default: result

setup:
	@fortune > foo
	@fortune > bar

$(call group_create,task1,foo bar,baz bob)
$(call group_target,task1): $(call group_deps,task1)
	@echo "running task 1"
	@cat foo bar > baz
	@cat bar foo > bob

$(call group_create,task2,baz bob,res1 res2)
$(call group_target,task2): $(call group_deps,task2)
	@echo "running task 2"
	@cat baz bob > res1
	@fortune > res2

result: res1 res2
	@echo "running task 3"
	@cat res1 res2 > result

clean:
	rm -f result baz bob res1 res2

allclean: clean
	rm -f foo bar

