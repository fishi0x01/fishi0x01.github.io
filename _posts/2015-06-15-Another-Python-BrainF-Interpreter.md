---
layout: post
title:  "Another Python BrainF*** Interpreter"
date:   2015-06-15 22:21:12 +0000
modified: 2015-06-18 02:06:58 +0000 
comments: true
disqus_id: 9
permalink: weblog/2015/06/15/another-python-bf-interpreter/
redirect_from:
  - /weblog/A/
categories: python
---

[BrainF***][wiki-brainfuck] (BF) is a famous esoteric programming language. 
Writing an interpreter for BF is actually easier or should I say at least easier to comprehend than writing an actual BF `Hello World!` program. 
Even though BF can theoretically be used to write any program, it is not practical to do so because of its low abstraction level. 
I guess that's one reason why it feels like I find more BF interpreters written in all kinds of languages scattered over many tech blogs rather than actual BF programs. 
Still, since I had a free day, a nice cold drink and the urge to script something I decided to add yet another Python BF interpreter to the web. 
Though for Python BF there are some nice one-liner code-golf-like versions out there, I chose the simpler approach of writing a structured, easy to comprehend version. <!--more-->

## BF Basics ##

Before we get started on the interpreter code itself, let's start off with some BF basics. 

In BF you have a memory of usually 30000 cells - also referred to as tape - and each cell holds one byte (0-255). 
You also have exactly one memory pointer initially pointing to the leftmost memory cell. 
Further, you have an instruction pointer keeping track of which operation to execute next. 

BF consists of only the following 8 operations: 

* `>`: shift the memory pointer 1 to the right
* `<`: shift the memory pointer 1 to the left
* `+`: increment byte in cell at memory pointer
* `-`: decrement byte in cell at memory pointer
* `.`: output byte from cell at memory pointer
* `,`: accept input and store in cell at memory pointer
* `[`: loop start: if byte in cell at memory pointer is zero, then jump to corresponding closing bracket `]`. 
Otherwise execute the next command.
* `]`: loop end: if byte in cell at memory pointer is nonzero, then jump back to corresponding opening bracket `[`. 
Otherwise execute next command.

As you can see the operations are quite simple and easy to comprehend. 
Apart from that, some additional constraints have to be taken into account:

* **Memory Borders**

As I have already mentioned BF usually has 30000 cells. 
The question now is what happens when the memory pointer is shifted beyond those limits? 
One way to handle this is by wrapping the pointer around, meaning when being shifted right from the right-most cell, the pointer goes to the left-most cell and vice versa. 
Another, simpler approach would be to throw a segmentation fault or some other kind of exception. 

* **Memory Space**

You could initialize a memory with the maximum amount of cells. 
If you only need a very small portion of that memory, than most of the memory was unnecessarily reserved. 
Another way would be to grow the memory on demand until it reaches its maximum allowed value. 
Whenever the pointer is moved to the right and the cell is not initialized yet, we then reserve the memory for that cell. 
The advantage of this method is obviously a more efficient space usage. 
The clear disadvantage is that each reservation costs time and thus influences the overall speed of the BF interpreter. 

* **Argument Input**

There are 2 major ways to get input. 
The first way is via standard user input via `STDIN`. 
It is easy to implement, but for longer repetitive programs quite annoying for the user. 
Another way is to use an extra file with input arguments.

## BF Loops ##

Most BF operations are very easy to implement and mainly consist of a few pointer movements. 
Depending on whether we decide to use memory wrapping or separate argument input files as described before, the complexity slightly rises, but is still very easy to comprehend. 

The only thing we should have a closer discussion about is the loop implementation. 
A naive way to implement the loop could be to move the instruction pointer until the corresponding closing or opening bracket is found. 
We must be aware of possible nested loops, meaning we have to count the occurrences of each bracket while looking for the matching ones - a stack structure might come in handy at that point. 
However, searching the source code for the corresponding bracket each time we encounter one is rather inefficient. 
At least we should remember the brackets in a map, so next time we can simply lookup the jump to the next instruction without searching. 
We could also pre-parse the code in order to make a map of all matching brackets, even before we start executing the first operation. 

## Finally - Some Code ##

Finally, let's have a look at some BF interpreter code!

{% gist fishi0x01/c47cded22b3271f7e16e pybf.py %}

This BF interpreter has no memory wrapping, so whenever the memory pointer moves beyond the limits, a SegFault exception is thrown. 
Further, an optional input file can be used to feed the input BF function `,`. 
In case no input file is provided or all bytes have already been read from the input file, the user has to provide input via `STDIN`.

In the first section we simply added some specific exceptions which might occur (such as SegFaults). 
In the second section we define a BF process which holds the context of our BF program. 
This class also implements every allowed BF operation and a code parse function. 
Finally, in the main routine we remove everything from our source code that's not BF code syntax, then build a context and execute the program. 
Prior to the first operation the code is parsed to get a map of the matching loop brackets. 

And finally, here is a BF `Hello World!`.

**hello_world.bf**
{% highlight brainfuck %}
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.
+++++++..+++.>++.<<+++++++++++++++.>.+++.------.
--------.>+.>.
{% endhighlight %}

When giving this code as an argument to our BF interpreter we should be able to see a `Hello World!`.


[wiki-brainfuck]: https://en.wikipedia.org/wiki/Brainfuck
