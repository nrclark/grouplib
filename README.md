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

$(call group, baz bob: foo bar)
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

frobnicate.sentinel: (conditionally depends on FROB_PHONY if baz bob are stale)
	touch frobnicate.sentinel

FROB_PHONY: foo bar
	frobnicate foo bar

result: baz bob
	cat baz bob result
```
But it wraps all that messiness into a macro so that you (the user)
don't need to worry about whether you missed this-or-that step in getting
grouped outputs off the ground.

The conditional dependence is key. Grouplib actually checks the sources (foo,
bar) and the targets (baz bob) during dependency evaluation, and decides whether
frobnicate.sentinel needs to depend on the real task (which is a phony), or
whether it has no dependencies and can just be a simple touch command.

## But seriously, how does it work? ##

It's magic. Use it and love it.

During the dependency evaluation of frobnicate.sentinel, a special function is
called which uses a auto-generated (and auto-deleted) Makefile passed to a
single sub-make, which is used to resolve rependencies and decide whether the 
targets need to be rebuilt (but not to do the building). If the groups targets
*are* out of date, then the PHONY task is enabled and the build is allowed to
run.

You can make as many groups as you want - this library will keep them all
straight and keep your dependencies managed.

API
---
Getting Grouplib into your Makefile is as easy as including it with include
`grouplib.mk`. Once it's in your Makefile, you get access to all the 
target-group goodness.

The functions provided by Grouplib are as follows:
 
### Normal use cases ###

Making a group is easy. Just take a rule that you'd like to be a group rule such as:

    group_outputs: group_deps
        [recipe for group_outputs here]

and wrap the first line into a function call:

    $(call group,group_outputs: group_deps)
        [recipe for group_outputs here]

### Grouplib Control ###

At the present time, Grouplib needs write access into a temp directory to store internally-created
files. By default, Grouplib uses the current working directory. If you want to change that, use:

`$(call set_grouplib_dir,target_directory)`

after you include grouplib but before you define your first target.
