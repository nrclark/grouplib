include ../grouplib.mk

default: result

setup:
	@fortune > foo
	@fortune > bar

foo bar: setup

$(call group,baz bob: foo bar)
	@echo "running task 1"
	@cat foo bar > baz
	@cat bar foo > bob

$(call group,res1 res2: baz bob)
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

