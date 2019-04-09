---
layout: post
title: "Measuring Traffic with iptables"
date: 2019-03-30 10:30:00 +0000
modified: 2019-04-09 09:30:00 +0000 
comments: true
disqus_id: 18
permalink: weblog/2019/03/30/measuring-traffic-with-iptables/
redirect_from:
  - /weblog/13/
categories: tooling
---

I recently read about a neat method of measuring traffic with iptables on linux hosts, which is nice for pentesting or infrastructure debugging. 
This is a rather short post describing that approach. 
<!--more-->

## Benefits of using iptables for traffic measurements

1. One nice thing about [iptables][iptables] is that it is very likely to be present on any linux server/client you run, so you dont need to install any extra packages. 
2. For infrastructure debugging/planning purposes you might need to know quickly how much traffic flows between 2 specific hosts/ports/... . Maybe you do not have monitoring in place yet or the monitoring is not fine grained enough (e.g., aggregating ALL packets on host interfaces).
3. In pentesting this is a fast and easy method to measure how much traffic/attention your operation produces. 

## Hands-on Example

Let us assume we want to quickly measure the traffic between the current machine and a remote host. 

Initially, we have empty iptables chains:

{% include tags/shell-start.html %}~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
{% include tags/shell-end.html %}

Of course some servers might already have rules attached and we do not want to mess with them. 
We create a new chain dedicated for our measurements:

{% include tags/shell-start.html %}~# iptables -N TARGET
~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain TARGET (0 references)
target     prot opt source               destination
{% include tags/shell-end.html %}

Now we attach measurement rules. 
We want to measure traffic between the current server and the machine 10.11.1.227 in our local network: 

{% include tags/shell-start.html %}~# iptables -A TARGET -d 10.11.1.227
~# iptables -A TARGET -s 10.11.1.227
~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain TARGET (0 references)
target     prot opt source               destination         
           all  --  anywhere             10.11.1.227         
           all  --  10.11.1.227          anywhere
{% include tags/shell-end.html %}

Next, we attach the new chain to input and output chains:

{% include tags/shell-start.html %}~# iptables -A INPUT -j TARGET
~# iptables -A OUTPUT -j TARGET
~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
TARGET     all  --  anywhere             anywhere            

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
TARGET     all  --  anywhere             anywhere            

Chain TARGET (2 references)
target     prot opt source               destination         
           all  --  anywhere             10.11.1.227         
           all  --  10.11.1.227          anywhere
{% include tags/shell-end.html %}

Now everything is in place. 
We can finally zero the packet and byte counters, trigger a command to produce traffic and verify that the traffic was counted:

{% include tags/shell-start.html %}~# iptables -Z
~# nmap -nA 10.11.1.227
..snip..
~# iptables -L TARGET -n -v -x
Chain TARGET (2 references)
    pkts      bytes target     prot opt in     out     source               destination         
    4663   353156            all  --  *      *       0.0.0.0/0            10.11.1.227         
    3061   214887            all  --  *      *       10.11.1.227          0.0.0.0/0
{% include tags/shell-end.html %}

We clearly see how many packets and bytes were transferred between the current server and 10.11.1.227.

{% include tags/hint-start.html %}
**NOTE:** Using [nmap][nmap] for port scanning is illegal in most countries. 
Use it only on networks that you own or for which you have explicit scanning permissions from the owner.
{% include tags/hint-end.html %}

After we are done we can cleanup:

{% include tags/shell-start.html %}~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
TARGET     all  --  anywhere             anywhere            

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
TARGET     all  --  anywhere             anywhere            

Chain TARGET (2 references)
target     prot opt source               destination         
           all  --  anywhere             10.11.1.227         
           all  --  10.11.1.227          anywhere            
~# iptables -D INPUT 1
~# iptables -D OUTPUT 1
~# iptables -F TARGET 
~# iptables -X TARGET 
~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
{% include tags/shell-end.html %}

Finally, here is a short script for setting up the chains and rules to measure traffic between 2 hosts:

**measureTraffic.sh**
{% gist fishi0x01/47bf14940e08650374ef9501e71feb5d measureTraffic.sh %}

[iptables]: https://en.wikipedia.org/wiki/Iptables
[nmap]: https://en.wikipedia.org/wiki/Nmap
