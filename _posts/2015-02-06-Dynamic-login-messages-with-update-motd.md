---
layout: post
title:  "Dynamic login messages with update-motd"
date:   2015-02-06 20:00:35 +0000
modified: 2015-06-22 13:13:17 +0000 
permalink: weblog/2015/02/06/dyamic-login-messages-update-motd/
comments: true
disqus_id: 4
redirect_from:
  - /weblog/5/
categories: linux sysadmin
---

Some time ago I was setting up my Debian server and I wanted to have a customized message on each login. 
In this post I will briefly introduce an easy way on how to create dynamic login messages which display a random session quote and some important system performance counters and information. 
This introduction is targeted for Debian and Ubuntu, because we will use the update-motd framework. <!--more-->
Here is the example we will create in this post: 

{% include tags/shell-start.html %}
<span style="color: #00FF00">  _____ .__         .__     .__ 
_/ ____\|__|  ______|  |__  |__|
\   __\ |  | /  ___/|  |  \ |  |
 |  |   |  | \___ \ |   Y  \|  |
 |__|   |__|/____  >|___|  /|__|
                 \/      \/     
 
Debian GNU/Linux 7.x</span>
 
<span style="color: blue">Session Quote:
 _______________________________
< Programmers do it bit by bit. >
 -------------------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
</span>
 
<span style="color:grey">System Information on Tue Jan 13 01:50:25 CET 2015
==================================================</span>
<span style="color:grey">CPU Usage         :</span> <span style="color:purple">1%</span>
<span style="color:grey">Memory Usage      :</span> <span style="color:purple">53.1%</span>
<span style="color:grey">Swap Usage        :</span> <span style="color:purple">3.3%</span>
<span style="color:grey">System Uptime     :</span> <span style="color:purple">25 days</span>
<span style="color:grey">IP Address        :</span> <span style="color:purple">3.3.4.5</span>
<span style="color:grey">Total Disk Usage  :</span> <span style="color:purple">6%</span>
<span style="color:grey">Open Sessions     :</span> <span style="color:purple">1</span>
<span style="color:grey">Running Processes :</span> <span style="color:purple">129</span>
 
<span style="color:#00FF00">Last login: Tue Jan 13 01:13:49 2015 from my.provider.12345.com
$</span>
{% include tags/shell-end.html %}

Debian and Ubuntu offer the update-motd framework which is provided by the libpam module. 
Each time a user logs into the system, `pam_motd` executes the scripts in `/etc/update-motd.d/` as root and writes the results to `/var/run/motd`, which is then displayed on the user's terminal. 
This makes it very easy to write dynamic login messages, since all we have to do is provide executable scripts in `/etc/update-motd.d/`. 

### Removing redundant information ###
As per default, the content from `/etc/motd` is printed on login. 
Further, notifications such as new emails or information about the last session are printed, for example: 

{% include tags/shell-start.html %}
Welcome to Debian GNU/Linux 7.x
 
You have new mail.
Last login: Tue Jan 13 01:00:39 2015 from my.provider.12345.com
$
{% include tags/shell-end.html %}

In order to get rid of these, we first have to remove all content from `/etc/motd`. 
Next, we have to comment out the following in `/etc/pam.d/sshd`: 

{% highlight Kconfig %}
# Print the status of the user's mailbox upon successful login.
#session    optional     pam_mail.so standard noenv # [1]
{% endhighlight %}

This will stop the mail notification from being printed. 
About the last session info: I personally like to have the information about when and where the last login session was, so I kept it. 
If you don't want it, you just have to change the following in `/etc/ssh/sshd_config`: 

{% highlight Kconfig %}
PrintLastLog no
{% endhighlight %}

{% include tags/hint-start.html %}
If you decide to change `/etc/ssh/sshd_config`, do not forget to restart the ssh daemon in order for the changes to take effect!
{% include tags/hint-end.html %}

### Header with random session quote ###
Now that we have removed the things we do not want, lets move forward to the things we want. 
We create the file `/etc/update-motd.d/00-header`. 
Make sure this file is executable as it will be used to print the header of our login session message. 
First, we add the static banner: 

{% gist fishi0x01/417de50e68d4b8d0f6f1.js header.sh %}

Next, we create a random session quote. 
The program `fortune` is ideal to print random quotes. 
Further, we can use `cowsay` to get the quote told by Tux himself. 
Simply append the following to the header script: 

{% gist fishi0x01/417de50e68d4b8d0f6f1 session-quote.sh %}

### Retrieving and printing performance counters ###
In a next step, we want to print some system and performance counter information. 
The stats are all available and just have to be transformed into a format of our liking. 
Most of this can be done using `awk` and `wc`. 
We create `/etc/update-motd.d/00-sysinfo` and ensure that it is executable. 
Inside the script we retrieve and print some interesting performance counters: 

{% gist fishi0x01/417de50e68d4b8d0f6f1 sys-info.sh %}

{% include tags/hint-start.html %}
If you want, there are many more things that can be done. 
For instance, in some cases I stumbled over motds that include the current weather report or temperature of the server's drives. 
Just make sure that the files in `/etc/update-motd.d/` are executable and keep in mind that the scripts are executed in alphabetical order.
{% include tags/hint-end.html %}

That's it! 
Now every time when you ssh to your server, you get an instant overview of interesting system counters (and a nice quote from Tux!).
