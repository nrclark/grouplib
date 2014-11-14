## Introduction ##

Make. The build tool that gives you just enough rope to hang yourself with. We
all love Make for its speed and simplicity. We love Make for all of its tricks
and arcane syntax. We also all hate Make for its tricks and arcane syntax.

GNU Make can do just about anything, and has all kinds of sweet features and
functions built right in.

Except one: Grouped targets.

It's crazy to think that if you have a task ('frobnicate', for example) that
produces multiple outputs simultaneously, GNU Make doesn't have the built-in
ability to track all of the outputs as a group.

That's where Grouplib comes in.

## The Problem ##

When trying to write a rule with multiple outputs, somebody might try this as a first pass:
```make
.PHONY: default

default: baz bob result

baz bob: foo bar
	frobnicate baz bob

result: baz bob
	cat baz bob > result
```
Under recent versions of Make, it will even do what you want. *Except in the parallel case*. When running make with -j (and sometimes under other circumstances), `frobnicate baz bob` will run multiple times. That might not be a big deal if `frobnicate` is something speedy like a 'touch' command or a C compilation, but it's a big problem if `frobnicate` is a process (such as compiling an ASIC design) that can take upwards of an hour.

So the next thing that people try usually looks something like this:
```make
.PHONY: default

default: baz bob result

baz bob: frobnicate.sentinel

frobnicate.sentinel: foo bar
	frobnicate baz bob
	touch frobnicate.sentinel

result: frobnicate.sentinel
	cat baz bob > result
```
This approach works. It does. It works in the parallel case, and in the single-threaded case. Unfortunately, it has some annoying quirks:

#) Tasks that are 'downstream' of baz and bob need to depend on frobnicate.sentinel instead of on baz and bob, if you want parallel builds to work properly. Which makes the dependency relationships in the Makefile more confusing.
#) You wind up with .sentinel files scattered around everywhere.
#) All of your grouped recipes need to create and manage their .sentinels.
#) If `frobnicate` screws up and produces baz without bob (or if you manage to manually delete baz), Make won't know that it needs to be rebuilt.

*If only there was a better way!*

# Produces baz and bob automatically
default: baz bob: foo bar
	frobnicate foo bar

result: baz bob
	cat baz bob result
```
The 
will result 




Grouplib is a pure GNU Make library that provides a set of user functions (which
can be called with GNU Make's 'call' command) for managing multi-target recipes.

It provides an automagic implementation of the 'sentinel' design pattern, where
.sentinel files are used to handle dependency-tracking on groups of targets that
are generated by a single recipe.

Grouplib creates, tracks, and deletes sentinels as required to keep your files
fresh. It's parallel-safe, and doesn't even leave yourproccess.complete files 
lying around anywhere! 

It uses a couple of very clever tricks to work out group-dependencies, and wraps
the tricks into a nice set of functions that you (the builder who doesn't want
to worry about how to make grouped-targets work robustly) can just call!
11111111111111111111111111111111111111111111111111111111111111111111111111111111

This library provides an automatic (and smarter) version of the following pattern: asdas asd asda sda sd asd asd as das 

```make
TASK1_SRCS = foo bar
baz bob: .sentinels/_task1.sentinel

.sentinels/_task1.sentinel: foo bar
	touch baz bob
	touch .sentinels/_task1.sentinel

rocklop: baz bob
	touch rocklop
```

Grouplib automatically generates and tracks the sentinel file(s) for
your target group(s), and also adds a special conditionial phony target
that forces a rebuild if any of the files are missing (to harden your
build against external interference or flaky toolchains).

With this library, the example above becomes:
 
```make
include grouplib.mk

TASK1_SRCS = foo bar
$(call group_create,task1,$(TASK1_SRCS),baz bob)

$(call group,task1): $(call group_deps,task1)
	touch baz bob
	$(call group_finish,task1)

rocklop: $(call group_outputs,task1)
	touch rocklop
```
You can make as many groups as you want - this library will keep them all
straight and keep your dependencies managed.

API
---

Getting Grouplib into your Makefile is as easy as including it with include `grouplib.mk`.
Once it's in your Makefile, you get access to all the target-group goodness.

The functions provided by Grouplib are as follows:
 
### Normal use cases ###

`$(call group_create,groupname,group_deps,group_outputs)`  
     Creates a target group.
 
`$(call group,groupname)`  
     Returns a handle to the target group's semaphore. Can be used in a
     dependency to list represent all of the group's outputs. Should be used
     as the sole target of the recipe that builds the target group.
 
`$(call group_deps,groupname)`  
     Returns a list of the group's dependencies. If any of the group's
     outputs are missing, this list includes a special PHONY target that
     forces a rebuild of the target group.

`$(call group_finish,groupname)`  
     Should be called as the last step in the target-group's recipe.
     Creates the sentinel directory if it is missing, and touches the
     target-group's sentinel.
 
### Advanced use cases ###

`$(call group_outputs,groupname)`  
     Convenience function for accessing the outputs assigned to the
     group during group_create.

`$(call group_sentinel,groupname)`  
     Returns the name of the target-group's sentinel. Equivalent to
     $(call group groupname).
 
`$(call group_all_sentinels)`  
     Returns a list of all sentinels currently being managed by
     Grouplib. Can be added to a global 'clean' list if desired.

`$(call group_getdir)`  
     Returns the directory currently being used by Grouplib
     to store its sentinel files. This directory is user-selectable.

`$(call group_setdir,dirname)`  
     Can be used to change Grouplib's sentinel directory to a
     user-specified value.

`$(call group_get_phonies)`  
     Provides a list of Grouplib's phony targets, so that they
     can be added to a .PHONY call if necessary. Note that in
     most cases, it won't be necessary to add them.
