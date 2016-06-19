---
layout: post
title:  "Enabling DCOM for Windows 7, 8 and Server 2012"
date:   2015-01-16 03:55:01 +0000
modified: 2015-06-18 02:03:21 +0000 
comments: true
permalink: /weblog/2015/01/16/enabling-dcom-windows-7-8-and-server-2012/
redirect_from: 
  - /weblog/2/
categories: c# windows dcom powershell
---

On a past project I had to develop a DCOM bridge. 
In this post I want to share my findings on how to prepare a Windows Machine for DCOM access.

For most DCOM bridge solutions, the `WbemScripting.SWbemLocator` class (WMI locator) is essential to gain administrator DCOM access to the computer. 
Having DCOM access to this class is very powerful (e.g., you can listen to any kind of events on the machine, you can retrieve performance counters etc...), which is why on Windows 7/8 and Server 2012 gaining access to it turns out to be more complicated than simply clicking a few check-boxes in the System Controls.<!--more-->

The problem is that by default the `WbemScripting` library cannot be accessed through DCOM. 
By default DCOM is not allowed to directly access DLLs. 
Even establishing the DCOM connection with administrator credentials does not solve the problem. 
There is a solution though. 
DCOM is allowed to access Executables (.exe) and Windows offers a process named dllhost.exe which can act as a surrogate for libraries we want to access via DCOM, meaning dllhost.exe can load the `WbemScripting.SWbemLocator` class, which makes it available for our remote DCOM connections. 
Inside the Windows Registry we can easily define which classes should be hosted by dllhost.exe. 

We need to know the CLSID of the class. For `WbemScripting.SWbemLocator` this CLSID is 76A64158-CB41-11D1-8B02-00600806D9B6. 

Before we finally start, please note that many important keys are owned by a so called `TrustedInstaller` user - this is also the case in our example. 
Even as administrator you do not have permission to change these keys. 
In order to change them, you first have to take ownership over them as administrator. 

### 32-bit machines ###
First, for the CLSID we need to create a key under `HKCR\CLSID`. 
Under this key we create an `AppID` having the value of the CLSID. 
This gives us:

```
HKCR\CLSID\{76A64158-CB41-11D1-8B02-00600806D9B6}
AppID = {76A64158-CB41-11D1-8B02-00600806D9B6}
```

Second, we need to create the `AppID` key we defined in `HKCR\AppID`. 
Further, we need to specify that this `AppID` is a DLL surrogate, meaning it will get loaded by dllhost.exe:

```
HKCR\AppID\{76A64158-CB41-11D1-8B02-00600806D9B6}
DllSurrogate=
```

Note, that the value for DllSurrogate is left empty! 

### 64-bit machines ###
Similar as with 32-bit machines, but instead of using `HKCR\CLSID\{76A64158-CB41-11D1-8B02-00600806D9B6}`, we define the key in `HKLM\SOFTWARE\Classes\Wow6432Node\CLSID\`:

``` 
HKLM\SOFTWARE\Classes\Wow6432Node\CLSID\{76A64158-CB41-11D1-8B02-00600806D9B6}
AppID = {76A64158-CB41-11D1-8B02-00600806D9B6}
```

### Automation of these steps ###
You can do all these steps manually using regedit.exe for example. 
Still, especially in professional contexts automated processes are preferred. 
It turns out to be quite complicated in Windows to take ownership of registry keys owned by `TrustedInstaller` without using 3rd party software such as [SetACL][setacl], but with a little C# magic and PowerShell it is still possible. 
I found a good description on how to take ownership of such keys on [Bedrich Chaloupka's blog][bedrich-chaloupka]. 
I took a base skeleton script from his post and modified it. 
The modified script first takes ownership over the necessary keys, then modifies them as previously discussed and finally resets the ownership back to `TrustedInstaller`. 
Here is the resulting C#/PowerShell-mix script which enables remote DCOM access on 64-bit machines to the `WbemScripting.SWbemLocator` class:

{% gist fishi0x01/ec5d356b5a189fe6f3f0bdb9a30e0144 dcom-access-x64.ps1 %} 

**IMPORTANT:** 

This script only works for 64-bit machines. 
You have to change the keys inside the script in order for it to work on 32-bit machines. 
This script works for me, but use it at your own risk. 
I do not guarantee that it works, nor do I give any kinds of support in case it doesn't.

{% include tags/hint-start.html %}
To avoid trouble, ensure that your Firewall is open on the ports designated for DCOM on your system. 
Also, keep in mind that the DCOM bridge has to be established with administrator credentials in order to have the necessary permissions. 
{% include tags/hint-end.html %}

Once remote DCOM is enabled, we could use Java to create a DCOM bridge from a client (could be Linux/Mac/Windows...) to this machine. 
This is handy in case we want to remotely retrieve performance counters or listen for WMI events. 
In the next post I explain how to build a [pure Java DCOM Bridge][weblog-3] to remotely monitor Windows machines. 


[setacl]: https://helgeklein.com/setacl/
[bedrich-chaloupka]: http://shrekpoint.blogspot.de/2012/08/taking-ownership-of-dcom-registry.html
[weblog-3]: http://fishi.devtail.com/weblog/3/
