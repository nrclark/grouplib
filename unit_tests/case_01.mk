
include ../grouplib.mk

default: task.2.out.1

setup:
	touch source.1 source.2

$(call group,task.1.out.1 task.1.out.2: source.1 source.2)
	echo "running task 1"
	touch task.1.out.1 task.1.out.2

task.2.out.1: task.1.out.1 task.1.out.2
	echo "running task 2"
	cat task.1.out.1 task.1.out.2 > task.2.out.1

clean:
	rm -f task.2.out.2 task.1.out.1 task.1.out.2

allclean: clean
	rm -f source.1 source.2

