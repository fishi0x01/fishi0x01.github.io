---
layout: post
title:  "Intercepting / Hooking function calls to shared C libraries"
date:   2015-01-25 16:36:27 +0000
modified: 2015-06-18 02:03:37 +0000 
permalink: weblog/2015/01/25/intercepting-hooking-function-calls-shared-c-libraries/
comments: true
disqus_id: 3
categories: c linux
---

I recently had to intercept function calls to my C socket library in order to implement a prototype for a Multi-source Multipath network protocol. 
That is why in this post I want to give a simple introduction on how to use the `LD_PRELOAD` environment variable to override shared C libraries. 
Further, I am going to show how to use `dlsym` to make calls to the original C functions from within our hooks.<!--more-->
{: .text-justify}

### Simple socket call interception ###

Lets create a simple program that opens a socket.
{: .text-justify}

**simple_client.c**

{% gist fishi0x01/68b24bc542f5cb09331e simple_client.c %}

The only thing this program does is creating a socket without binding it to an address. 
Compiling and running this program gives us:
{: .text-justify}

{% include tags/shell-start.html %}
$ gcc -Wall simple_client.c -o simple_client
$ ./simple_client
Socket successfully created
$
{% include tags/shell-end.html %}

Now we want to intercept the `socket()` function to change the behavior on each call. 
For this, we first have to write a shared library that will override the `socket()` function. 
{: .text-justify}

**socket_hook.c**

{% gist fishi0x01/68b24bc542f5cb09331e socket_hook_trivial.c %}

With the help of `LD_PRELOAD` we can now let our `socket_hook.so` library get loaded before the standard C libraries, meaning the first occurrence of the `socket()` function is in our shared library. 
This results in the following:
{: .text-justify}

{% include tags/shell-start.html %}
$ gcc -Wall -fPIC -shared socket_hook.c -o socket_hook.so
$ LD_PRELOAD=./socket_hook.so ./simple_client 
socket() call intercepted
Error : Could not create socket
$
{% include tags/shell-end.html %}

Please note, that the Error message is due to the fact that we return -1 in our shared library, but our client code expects a non-negative return value. 
So far, we could override a standard `socket()` call with our own function from our shared library. 
{: .text-justify}

### Calling the original socket library from inside our hook ###

In a next step we also want to call the original `socket()` function from our shared library. 
This will enable us to easily add additional functionalities to existing standard C libraries without changing or rewriting the original libraries. 
Also, when implemented properly, we could achieve total transparency to the calling layer. 
Lets change our previous socket hook.
{: .text-justify}

**socket_hook.c**

{% gist fishi0x01/68b24bc542f5cb09331e socket_hook.c %}

We use `dlsym` with `RTLD_NEXT` from `<dlfcn.h>` to find the next occurrence of the `socket()` function and store the location in `o_socket`. 
Hence, in our example `o_socket` can from then on be used to call the original `socket()` function. 
`_GNU_SOURCE` has to be defined in order to be able to use `RTLD_NEXT`. 
We now have to compile our shared library differently from before:
{: .text-justify}

{% include tags/shell-start.html %}
$ gcc -Wall -fPIC -shared socket_hook.c -o socket_hook.so -ldl
{% include tags/shell-end.html %}

Using our new shared library gives us the following:
{: .text-justify}

{% include tags/shell-start.html %}
$ LD_PRELOAD=./socket_hook.so ./simple_client 
socket() call intercepted
Socket successfully created
$
{% include tags/shell-end.html %}

That's it! 
We have successfully intercepted the socket function and made a call to the original socket library. 
We could now simply add some additional behavior to the `socket()` call. 
We could also easily intercept further functions such as `read()` or `write()`, to be able to build a new transparent layer on top of the socket library - ideal for writing quick networking prototypes.
{: .text-justify}
