# mobamb - Mobile Ambients and Flow Logic

This project represents a flow logic analyser for the mobile ambients calculus.

[https://www2.imm.dtu.dk/GLOBAN/Nielson_1.pdf](FLOW LOGIC - Flemming Nielson & Hanne Riis Nielson)

One of the aims of the project is to perform as much analysis as possible at compile-time.

Also included is a runtime model with a rule-set based on the static analyser.

The model represents a virtual ambient machine, and hosts mobile agents that react to conditions in the process structure within the ambient simulator.

Co-algebras, typed, secure safe, and boxed, ambients are supported.
I also want to model the privileges system, and the secret ambients.

We may use the join calculus to set "policies" which are basically user-definable capabilities.
These setup strict rules about what can and cannot cross over ambient process boundaries.

The simulator may be launched as a service, or single-user application, and process text commands written in the ambient syntax.

### Mobile Ambients

Mobility and evaluation occur within a single thread, inside a given HostAmbient.
Whilst capabilities is being evaluated, no mobility will occur during the synchronised phase.
This is also true for processes invoked from the join table, and during all IO operations.
The host ambient maintains a table of tags that represent the potential operations that may occur.
Tags are randomly selected for sequential execution from the pool.
The rule for process mobility is only true across ambient boundaries - a process may change it's parent, but it may not
enter an ambient or leave the enclosing ambient outside of the guarded thread.

The flow tracker also uses the same tags to indicate branches in the matrix.
Each tag contains a back-link to the process capability which proves the
validity of the tag, and this is called a lemma.
Finally, each tag is attached to a particular mobile-ambient.

In the runtime model, tags are evaluated in a single thread in the host ambient.
Two psuedo-capabilities, enter and leave, are defined, which form the building
blocks of all mobility operations.  Boundaries between ambients are held to be
synchronous - that is, mobility operations are serialised over the host-ambient.
If an ambient leaves the host-ambient, it cannot be guaranteed that it will
have entered the enclosing ambient when the next operation is processed.
The leave pseudo takes a single parameter, and the name of the current
enclosing ambient must match this parameter, otherwise a fault occurs.
After the psudo-cap is exercised, the process will be orphaned, with a
parent of null.
The enter pseudo takes a single parameter, and this may be any ambient.
However we test that the attached capability lemma indeed refers to a
child or parent ambient, according to the rules of mobility.
To enter an ambient, the process must be an orphan, ie it's parent must be null.

The Ambient hierarchy is guaranteed not to change outside the serial thread of
the host ambient.
We also have the 'exit' cap which assigns a 'leave' to every child process.
A child can never 'leave' if the co-capabilities disallow it. this replaces
'open' which becomes a part of the defined library capabilities, which are
extensible.
Co-capabilites have their own set of psuedos, which includes 'allow'
and 'prevent', which can

Open caps are emulated by assigning all children of n the psuedo-cap 'leave'
(via the exit psuedo-cap) causing them to exit the opened ambient.
next the ambient is assigned the psuedo-cap 'leave'.

in n := leave.enter n
out n := leave.enter n:parent


#### tag generation rules (precedence)
In the static analyser, all combinations of tags are processed, and
a new permutation of the process graph is generated for each tag.
any process which is restricted is excluded from the graph.

in the runtime dynamic analyser, a step-through model is used,
where we evaluate each process in turn and determine which rules we apply to
update the graph.

if a matching in cap is found, then no further in or output tags are generated.
if a matching out or (bound) input is found, no further tags are generated.
tags are evaluated from the top process (the host) and proceed with each
child process, in any order. tag generation halts when an out or an input
with a matching output are found, and the operation processed.
the evaluation also halts when an in match is found, where we
already have a matching in, or if more than one output occurs; the halt occurs before tag generation - therefore,
only one in match can be processed, and one output, but it may be processed alongside an
either or both an out or an input.
after generation, tag processing begins. all available tags are processed, and these
are removed from their parent processes. only the pseudo-tags enter and leave
and read are processed differently, because they form the building blocks by
which the other tags exercise the capabilities of their parent processes.

the tag processing occurs in

#### Host ambients

host ambients are not mobile themselves, although their parents might.
special rules are used for boundary crossing of host ambients, and this includes
pi from sources external to the host. all pi and all mobility are synchonised
about the host.


enter and leave are the only capabilities that do not result in the creation of a
new software task, and are processed inline by a dedicated machine thread (per-host) ensuring
that mobility is synchronous. The pi states are also updated here, and this
includes three operations: input, output and extrude.

extrude is a special operation.
a single visible extrusion (defined by the environment) is exposed to each process.
the extrude operator returns the name of a pi channel which can then be used to transmit data
to the environment.
and this is also done using process tags - so the process has access to the synchronous
mobility feed.
and this can apply to partial restricted processes too, because the type domain
attached to the process, and passes through the traversal.
this includes partial joins.
and if the target host of the migration is an interpreter, the function can export
itself as raw source-code. otherwise, a serialised form of a reference to a
particular name is represented on a matching join in the remote host.
So the output of the join compiler has to allow multiple entry points for each
function, as well as match against the variety of types which may be passed as
input tuples by potential users of the functions.

### synchronization of joined and mobile operators

because the joins are processed "inline" (ie by the tag processing thread)
a method invoked by the join should never block or throw.

the only time a tag may be processed by a thread other than the
one attached to the tag pool is when an output occurs (from a remote
  host ambient) and a matching input is waiting in the local host ambient.
In this case, the input is processed by the remote ambient. However
it is not customary to modify the process hierarchy during an input,
the hierarchy could become modified (by the host's own thread) whilst
the input join is being executed.

so to escape special conditions:
if a joined method wished to perform external operations such as IO
which may block, it should do so in a new thread not attached to the
tagging layer.
any operation from an IO statement should not affect the hierarchy
so to perform an operation such as creating a new process, the
receiver should submit a tag for evaluation by the mobility thread.

tag creation is synchronised and may simply fail, meaning that the
creation was blocked.
the pool stores a set of tags for evaluation. these are structured so
that several mobility operations may be performed in a single cycle.

tag generation starts when a host evaluation method is called.
tags are created for matching capabilities and stored in the pool.
if an ambient has a matching 'out' cap, a tag is generated.
otherwise, it is checked for matching 'in' caps of it's siblings.

when a child ambient enters, the siblings are checked for matching 'in'
caps.

when an ambient enters a new parent, it's caps are checked for a
matching 'out'.

if co-caps are enabled, these form part of each check.

pi is checked before and after mobility.
a waiting input with a matching output is processed first.
secondly, unmatched outputs are added to the local domain.
then inputs are added one by one and checked against the
waiting outputs.

### Domains, Process Types and Type Constants

These are the three main elements in a program, in the ambient functional syntax.

Domains represent areas of functional space, in which types may be defined.
Each type represents a curve, or more specifically, a spline, where we specify
intersection points where domains intersect.

Domain axes are seen as terms, which are accessed using names.

We provide three types of binding.
A child domain, which is subsumed by the parent.
A process type, which is an applied function in the domain, so for example,
the statement P|Q creates two process types, P and Q.
A type constant, which is a functional pattern or rule, that can be applied to
a process type. So for example, if we bind P as a constant that resolves to r,
then the statement P|Q would resolve to r|Q. and this is exactly the same as saying
(P|Q){P/r} .
or we could bind P to a constant A[Q], in which case, P|Q resolves to A[Q]|Q
when a process tag is evaluated, it is assumed that all the rebinding has been
completed. however, type constants are evaluated lazily, and are represented
as a simple function calls in the code. any function may be bound as a type constant.
ambient names and so on are all type constants. every type constant is also a
named channel in pi. when mobility occurs, it is done through this hidden pi layer,
via the implicit channel attached to the name of the mobile process.
each process secretly has only one extrusion (it's own name) and this is a vector
of the names available in the runtime type domain of the process.
the extrusion contains the bound names x[] and y[] which are the up and down tuples
representing pi at that location. capabilities are listeners on these channels;
so when an ambient moves in to a host process, the name is broadcast to the
sibling processes that have matching capabilities, causing tags to be generated.
the ambient has hidden processes attached, that listen for input on the local
extruded channel, indicating that the ambient has a new parent. this process
then checks the local capabilites and notifies any that match, causing tags
to be generated.

the implicit names are attached to extrusions that perform the bookkeeping of
updating the locations of each process. the bookkeeping also involves updating
the tags attached to each ambient process. a provenance chain is created that
provides the evidence for the location of each process. at each point in process
flow, we can extrapolate the exact conditions that caused the presence of a process
at a particular location.
One example application for this would be an analyser which generates a
process graph from a given piece of source-code in a particular known programming
language which is congruent with the compiled application.

The analysis is used to emulate the program, and discover bugs that can
be back-traced to exact locations in the source code that would be unnoticed by
a standard compiler, and potentially, when coupled with an ML processor,
propose changes to the source-code to make it more efficient and reliable.
A back-propagating network could be trained alongside the analysis.

The type data are also expressed in meta-format, in a separate graph, so that
a type environment may be queried for further information about a type-constant or
process in it's domain.

Tags are a special kind of meta-data attached only to ambients. These are not
accessible outside the analysis simulator.

Only the type domain (and environments) are accessible to the local process.
The type domain represents the entire state of the process, it's location,
pi bindings, and so forth. The structures representing the process in the
graph are not exposed to the application. To perform any actions, processes
utilise special pi bindings known as extrusions. Really, there is only one
extrusion - the process name - and this is used to access the process
mobility layer. We can exercise capabilities, create and close child processes,
and perform io, by addressing a hidden pi channel which has the name of the
process. these operations are restricted to trusted processes.
dubious processes are only permitted a pre-defined set of capabilities.
special capabilities are marked with a star (asterisk), for example \*enter
and \*leave.

We have special operators to tell us whether a name is \*bound
or \*unbound in a domain.

And we have operators to check against grouping, \*is and \*not ,
so that a statement `in P`
can match any ambient in the group P, if the name P represents a type constant
with those operators assigned.

### Join syntax (pi)

Join calculus is used to attach functional augmentations known as extrusions to the process tree.

Every function takes two parameters, the tuple of inputs x[] and the tuple of outputs y[].
We can write these using the join syntax attached to our process as an augmentation (UDA in d-language, annotations in java, etc).
Or we can have the join compiler output sourcecode to a set of files, by expanding statements in a file written in the join syntax.
Standard programming languages are used for these, and the statements are mapped into
extrusions in the process graph using clauses written in a special language.
These clauses deal with tuples representing names bound in pi, and also the names of the
current process and the parents in the hierarchy.
The tuples are divided into two groups - up tuples (inputs) and down tuples (outputs).
We visualise each process as a curve in the functional spectrum, with inputs above and outputs below.
Parts of the function may be restricted, but we can still perform analysis on the remaining parts
because the restricted part may be unnecessary for a particular flow check.
When a function tries to read an unbound "up" tuple, or if it writes to a (really, 'the') "down" tuple before the preceding
value has been consumed, the function yields.

A unique type domain is attached to every process, and the type domains are "parallel" at the level of the
enclosing ambient.
A type domain can become "restricted", which means that it has unresolved bindings, and the attached process
will be excluded from processing, but will still be included in the graph as a partial analysis.

In this way ordinary source-code can define a mixed model, by using attribute statments to attach an extrusion to any declaration in the program.

The machine provides a mechanism whereby a method or function may yield, and then become a partial function, which can migrate to another agent,
possibly on a different host. We call this "ghosting".

example:
P := {
  n = x[0] + 3
  y[0] = n + x[1]
}

compiles to code which reads x[0] from pi, adds three to it, and binds the result
as n.
the process then reads x[1] and lastly, y[0] is assigned the sum of this with the value of n.

lets say the process receives x[0] but is then migrated to a different parent.
the value of n is also migrated because the local domain is attached to the process and will
be rebuild inside the remote process.

so in effect, we can switch the parent of a type domain
and the bindings will reflect the migration. bindings local to the process however, will remain intact.
the rebinding is done at the level of the "local ambient", meaning it's first parent in the process hierarchy
that is a mobile ambient - the "enclosing ambient".

We can also write restriction policies.
Lets say we have a domain alpha, and two restrictions
(v n)Q
(v m)(v n)Q

Q cannot exist twice in alpha, so if both n and m are bound, we have an error
because we have two values Q. so the restriction policy is used to supply
a new value for Q that we generate to override the restriction.

Join statements

we create a join by attaching some process P to a match set.
The match can contain processes and elements from local pi bindings.

eg.
lets say we have a process -

P := Q[R[S]]

we can add a join to S in this location:

in P [
 Q.R.S in {
   // body of the join...
 }
]

or we want a join with an input :

P := Q[R[S]]|<n>

in P [
 Q.R.S in (^string) {
   // body of the join...
   // x[0] is bound to n
 }
]
an input at Q.R.S bound to the up tuple ^n


:= Q[R[S]]|<n>.<m>

in P [
  (^string . ^string)
  Q.R.S in {
   // body of the join...
   // x[0] is bound to n
   // x[1] is bound to m
   // this match will fire when two 'string' type outputs are available,
   // and the process S exists in both R and Q.R .
   // because there is only one input path, the function will never yield.
 }.{
   // body of a second join,
   // parallel to the first, but matching the same tuple vector.
 }
]
an input at Q.R.S bound to a string up tuple and then another one up bound to string.


P in [
 (^string . ^string)(^string)
 Q.R.* in  {
   // body of the join...
   // any process in Q.R .
   // the match fires when a single string is available.
   // if any part of the join that reads the second string will be restricted
   // if the second string is unavailable, the join yields.
   // x[0] is bound to n
   // x[1] is bound to m
 }
]
an input at Q.R.S bound to a string up tuple and then another one up bound to string,
or to simply a string bound to an up.
Code which uses the second input x[1] will be automatically restricted, until
the value is bound. the value may be seen as optional.

A yielded function is basically the same as a process waiting on a pi input capability,
except that it may be waiting for more than one value, and it may be discarded, re-processed
or restricted, due to changes caused by ambient mobility.

Use Cases
=========

Parser and compiler generator
-----------------------------
The ambient types match against statements in a defined grammar file, such as a PEG grammar.
Compilation is done using the ambient flow tracking tool.
After processing, the output would be the source code for the processes defined in the ambient logic.
So the flow analysis helps define which output statements are used for the entities defined in the input to the compiler using the schema defined by the
grammar, and a set of rules in ambient syntax that define the behaviour of the compiler.

The compiler would be an executable program, and this would parse code according to the provided definition.
Flow analysis proves that the compiled can parse any valid input, because the potential permutations of the process graph have been rendered as cases in the parser.
So we know that if an error occurs in the anaylsis, the exact point in the source code can be reached by rewinding the flow graph.

The parser would send signals via a pi extrusion and these can be hooked into functions that control the output.
The process has an environment which contains a set of procedures that has capabilities to open files and emit binary data.
These are defined using the join syntax and standard meta-data syntax is used to apply these to the relevant statements in an ordinary programing language.

We hope to obviate the need for a separate "makefile" in our applications and have instead a global policy for each file type, that we can override using inline
metadata in the source code.
This means that the flow analyser would need to know which tools to invoke, and there would be a library of commands for each tool.

Stage one would be prototype XML and JSON etc parsers.

Eventually we would be able to specify any platform or target, and the compiler would re-analyse the entire codebase and this is done in parallel to the
generator, so there are two process trees running.

So for any valid input, we could generate, for example:
autotools "configure" and Makefile for a project.
Vagrant or Docker definitions to launch pre-configured application.

We can produce any output, not necessarily an executable program, but images or sound files, or the data could be sent to a socket.
The output could be an agent that migrates to a remote system.
