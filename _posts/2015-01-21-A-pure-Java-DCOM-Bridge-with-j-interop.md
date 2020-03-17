---
layout: post
title:  "A pure Java DCOM Bridge with j-interop"
date:   2015-01-21 01:41:43 +0000
modified: 2015-06-18 02:03:29 +0000 
comments: true
disqus_id: 2
permalink: weblog/2015/01/21/pure-java-dcom-bridge-j-interop/
categories: dcom java
---

For a past project I had to develop a Java DCOM bridge with [j-interop][j-interop] (version 3.0) and in this post I want to share my findings on this topic. 
{: .text-justify}

j-interop is a free library for pure Java DCOM bridges to Windows WMI devices. 
Sadly there haven't been any updates for about 2 years now, but for me this library worked magic.<!--more-->
{: .text-justify}

**Only requirements:**

* Since we are using Java, the client side needs at least a JRE
* The Windows WMI device has to be DCOM enabled for the `WbemScripting.SWbemLocator` class. 
How this is done I explain in detail in [this post][blog-enable-dcom].
{: .text-justify}

First, you have to download the j-interop jar from [here][j-interop-jar] and add it to your project's classpath. 
{: .text-justify}

### Disable auto-registration ###

Be sure that auto-registration is disabled, by calling `JISystem.setAutoRegistration(false);` somewhere in your initial routines.
{: .text-justify}

Windows will not allow remote fiddling with the registry keys through j-interop. 
If you do not disable auto-registration, you will run into Access Denied errors
{: .text-justify}

### Create DCOM Session ###

Next, for a DCOM connection, j-interop first has to create a JISession. 
For full access, this session is created with administrator credentials from the Windows WMI machine:
{: .text-justify}

{% gist fishi0x01/51f6b1b2ea81f112a3ea CreateDCOMSession.java %}

### Create COM Server ###

Next, we need to create a JIComServer object from the `WbemScripting.SWbemLocator` class: 
{: .text-justify}

{% gist fishi0x01/51f6b1b2ea81f112a3ea CreateCOMServer.java %}

### Connect to WMI namespace ###

WMI consists of multiple namespaces. 
You have to connect the `WbemScripting.SWbemLocator` object to one namespace before we can retrieve objects from it. 
Which namespace to connect to depends on what class you want to retrieve. 
In our examples we use the `root\cimv2` namespace, which is used for Computer System Hardware Classes, Operating System Classes, Performance Counter Classes and WMI Service Management Classes. 
If you want to retrieve events from MSSQL server classes from running instances, the namespace is `SQL`. 
{: .text-justify}

{% gist fishi0x01/51f6b1b2ea81f112a3ea ConnectWMINamespace.java %}

### Query performance counters ###

We can now use the `WbemScripting.SWbemLocator` for WQL (WMI Query Language) queries (similar to SQL syntax, but less powerful (no joins...)) to obtain machine performance counters (e.g., Memory/CPU usage, Network interface stats...) or listen for events (e.g., nny event from the Windows Event Viewer or thrown Events from self-made ASP applications...). 
For instance we could query the Disk IO performance: 
{: .text-justify}

{% gist fishi0x01/51f6b1b2ea81f112a3ea QueryCounters.java %}

### Listen for WMI events ###

The WMI object attributes and methods that we can invoke are explained in the [Microsoft WMI docs][microsoft-wmi-docs]. 
Besides querying performance counters, we could also subscribe a listener to listen to events occuring on the Windows machine:
{: .text-justify}

{% gist fishi0x01/51f6b1b2ea81f112a3ea WMIEventListener.java %}

{% include tags/hint-start.html %}
Even in case the listener is not actively waiting (blocked state in `NextEvent` Call), the events do not get lost. 
Through our initial subscription the events are being stored at the remote Windows machine until we make the `NextEvent` Call or the WMI connection is shutdown. 
{: .text-justify}
{% include tags/hint-end.html %}

That's it! We can now easliy remotely monitor our WMI target machine.
{: .text-justify}

[blog-enable-dcom]: /weblog/2015/01/16/enabling-dcom-windows-7-8-and-server-2012/
[j-interop]: http://j-interop.org/
[j-interop-jar]: http://sourceforge.net/projects/j-interop/files/
[microsoft-wmi-docs]: https://msdn.microsoft.com/en-us/library/aa394388%28v=vs.85%29.aspx
