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

That's where Grouplib comes in. It features:
 - Makes target groups work in your parallel builds
 - Does it using pure GNU make (with some clever tricks)
 - Does it without leaving a bunch of .sentinel files lying around.

## The Problem ##

When trying to write a rule with multiple outputs, somebody might try this as 
a first pass:
```make
.PHONY: default

default: baz bob result

baz bob: foo bar
	frobnicate foo bar -o baz bob

result: baz bob
	cat baz bob > result
```
Under recent versions of Make, it will even do what you want. *Except in the
parallel case*. When running make with -j (and sometimes under other 
circumstances), `frobnicate baz bob` will run multiple times. That might not be
a big deal if `frobnicate` is something speedy like a 'touch' command or a C
compilation, but it's a big problem if `frobnicate` is a process (such as
compiling an ASIC design) that can take upwards of an hour.

So the next thing that people try usually looks something like this:
```make
.PHONY: default

default: baz bob result

baz bob: frobnicate.sentinel

frobnicate.sentinel: foo bar
	frobnicate foo bar -o baz bob
	touch frobnicate.sentinel

result: frobnicate.sentinel
	cat baz bob > result
```
This approach works. It does. It works in the parallel case, and in the
single-threaded case. Unfortunately, it has some annoying quirks:

1. Tasks that are 'downstream' of baz and bob need to depend on
frobnicate.sentinel instead of on baz and bob, if you want parallel builds to
work properly. Which makes the dependency relationships in the Makefile more
confusing.
1. You wind up with .sentinel files scattered around everywhere.
1. All of your grouped recipes need to create and manage their .sentinels.
1. If `frobnicate` screws up and produces baz without bob (or if you manage to
manually delete baz), Make won't know that it needs to be rebuilt.

*If only there was a better way!*

## The Solution ##

Lucky for you: I figured out This One Weird Tip From a Mom and wrote it into
a library.

Now the example above can be expressed like this:
```make
include grouplib.mk

default: result

$(call group_create,task1,foo bar,baz bob)
$(call group_target,task1): $(call group_deps,task1)
	frobnicate foo bar -o baz bob
 
result: baz bob
	cat baz bob > result
```
Grouplib handles the creation of phonies, sentinels, and all kinds of other
unseemly things. It also handles the deletion of all of these things, so to the
user it should be completely transparent.

## How does it work? ##

Grouplib works by setting up rules for you that look like this:
```make

default: result

baz bob: frobnicate.sentinel
	(test for baz and bob's existence)
	rm -f frobnicate.sentinel

frobnicate.sentinel: (conditionally depends on FROB_PHONY)
	touch frobnicate.sentinel

FROB_PHONY:
	frobnicate foo bar

result: baz bob
	cat baz bob result
```
But it wraps all that messiness into a nice set of macros so that you (the user)
don't need to worry about whether you missed this-or-that step in getting
grouped outputs off the ground.

The conditional dependence is key. Grouplib actually checks the sources (foo,
bar) and the targets (baz bob) during dependency evaluation, and decides whether
frobnicate.sentinel needs to depend on the real task (which is a phony), or
whether it has no dependencies and can just be a simple touch command.

## But seriously, how does it work? ##

It's magic. Use it and love it.

During the dependency evaluation of frobnicate.sentinel, a special function is called
which uses a auto-generated (and auto-deleted) Makefile passed to a single sub-make,
which is used to resolve rependencies and decide whether the targets need to be rebuilt.
If they do, then the PHONY task is enabled and the build is allowed to run.

You can make as many groups as you want - this library will keep them all
straight and keep your dependencies managed.

API
---
Getting Grouplib into your Makefile is as easy as including it with include
`grouplib.mk`. Once it's in your Makefile, you get access to all the 
target-group goodness.

The functions provided by Grouplib are as follows:
 
### Normal use cases ###

`$(call group_create,groupname,group_deps,group_outputs)`  
     Creates a target group. Should be called before using group_target, or any
     other commands that operate on the group.

`$(call group_target,groupname)`  
     Returns a handle to the target group's private PHONY. Should be used as the
     sole target for the recipe that actually builds your files. Can also be used
     for reference, if desired.

`$(call group_deps,groupname)`  
     Returns a list of the group's dependencies (as defined at the time of
     group_create). This is provided as a convenience wrapper.

### Advanced use cases ###

`$(call group_outputs,groupname)`  
     Convenience function for accessing the outputs assigned to the
     group during group_create.

`$(call group_sentinel,groupname)`  
     Returns the name of the target-group's sentinel. Equivalent to
     $(call group groupname). Note that sentinels are generally
     auto-deleted. You won't normally see them.
 
`$(call group_all_sentinels)`  
     Returns a list of all sentinels currently being managed by
     Grouplib. Can be added to a global 'clean' list if desired.

`$(call group_getdir)`  
     Returns the directory currently being used by Grouplib to store
     its sentinel files. By default, the storage directory is '.',
     but it's user-selectable with group_setdir below.

`$(call group_setdir,dirname)`  
     Can be used to change Grouplib's sentinel directory to a
     user-specified value, in case you want the temporary files
     to live in a particular location. If you want to use this, call
     it before using group_create.

`$(call group_get_phonies)`  
     Provides a list of Grouplib's internal phony targets, so that they
     can be added to a .PHONY call if you want to be thorough. Note that
     in most cases, it won't be necessary to add them.

`$(call group_get_intermediates)`  
     Provides a list of Grouplib's internal intermediate targets, so that they
     can be added to an .INTERMEDIATE: call if you want to be thorough, and/or
     to your 'clean' target. Note that in most cases, Grouplib will delete 
     its own intermediates as soon as it's finished with them.
