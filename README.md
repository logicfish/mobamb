# mobamb - Mobile Ambients and Flow Logic
Mobile Ambients

This project represents a flow logic analyser for the mobile ambients calculus.

[https://www2.imm.dtu.dk/GLOBAN/Nielson_1.pdf](FLOW LOGIC - Flemming Nielson & Hanne Riis Nielson)

One of the aims of the project is to perform as much analysis as possible at compile-time.

Also included is a runtime model with a rule-set based on the static analyser.

The model represents a virtual ambient machine, and hosts mobile agents that react to conditions in the proccess structure within the ambient simulator.

Join calculus is used to attach functional augmentations known as extrusions to the process tree.

In this way ordinary source-code can define a mixed model, by using attribute statments to attach an extrusion to any declaration in the program.

The machine provides a mechanism whereby a method or function may yield, and then become a partial function, which can migrate to another agent, 
possibly on a different host. We call this "ghosting".

Co-algebras, typed, secure safe, and boxed, ambients are supported. 
We use the joins table to set "policies" which are basically user-definable capabilities.

The simulator may be launched as a service, or single-user application, and process text commands written in the ambient syntax.

Mobility and evaluation occur within a single thread, inside a given HostAmbient.
Whilst capabilities is being evaluated, no mobility will occur during the synchronised phase.
This is also true for processes invoked from the join table, and during all IO operations.
The host ambient maintains a table of tags that represent the potential operations that may occur.
Tags are randomly selected for sequential execution from the pool.
The rule for process mobility is only true across ambient boundaries - a process may change it's parent, but it may not
enter an ambient or leave the enclosing ambient outside of the guarded thread.

The flow tracker also uses the same tags to indicate branches in the matrix.

Use Cases
=========

Parser and compiler generator
-----------------------------
The ambient types match against statements in a defined grammar file, such as a PEG grammar.
Compilation is done using the ambient flow tracking tool.
After processing, the output would be the source code for the processes defined in the ambinet logic.
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
