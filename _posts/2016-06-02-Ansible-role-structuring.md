---
layout: post
title:  "Ansible role structuring"
date:   2016-06-02 15:47:09 +0000
modified: 2016-06-03 00:18:00 +0000 
comments: true
permalink: weblog/2016/06/02/ansible-role-structuring/
redirect_from:
  - /weblog/D/
categories: ansible
---

In this short post I want to talk about structuring Ansible roles in a way that OS specific tasks and variables are cleanly separated from the other common logic of the role. 

My main sources of inspiration for role structuring are [Ansible Galaxy][ansible-galaxy] and the [DebObs repository][ansible-debops] and I would like to share my findings here.<!--more-->

## A simple ssh role ##

Let's first quickly discuss the directory structure of an Ansible role. 
In general, we have a `tasks` directory, which contains each task that has to be executed for that role. 
Further, we got the `handlers` directory, which contains service handlers which can be called from any task. 
We also have a `vars` directory, which as the name already can contain variables. 
Jinja2 templates and static files are being stored inside the `templates` and `files` directory respectively. 
Another common directory is the `defaults` directory, which could be used for OS independant variables. 

<pre>
ssh
├── defaults
├── files
├── handlers
├── tasks
├── templates
└── vars
</pre>

In each directory, except `files` and `templates`, the file `main.yml` gets included automatically when you use the role. 

Now, to write our ssh role for Ubuntu 14.04 we would need a template for the sshd configuration. 

**templates/sshd_config.j2**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-templates-sshd_config.j2 %}

Next, we need a handler for the sshd service. 

**handlers/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-handlers-main.yml %}

Further, we need tasks which ensure that sshd is installed and the ssh config template gets rendered and deployed. 

**tasks/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-tasks-main.yml %}

Finally, we could define some common variables.

**defaults/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-defaults-main.yml %}

## A more mature role structure ##

While the above approach does work for Ubuntu 14.04, we still would like to easily extend our role for any other OS too. 
One easy way to do so, is by separating OS specific tasks and variables in different OS dedicated files. 
Ansible helps us to automatically identify the currently used distribution with `{% raw %}{{ ansible_distribution }}{% endraw %}` and `{% raw %}{{ ansible_distribution_version }}{% endraw %}`, so we just have to name the OS dedicated yml files accordingly and include them in our `main.yml` files. 

For our ssh role, the dir tree would then look something like that:

<pre>
ssh
├── defaults
│   └── main.yml
├── handlers
│   ├── main.yml
│   └── Ubuntu14.04.yml
├── tasks
│   ├── main.yml
│   └── Ubuntu14.04.yml
├── templates
│   └── Ubuntu14_04.sshd_config.j2
└── vars
    └── Ubuntu14.04.yml
</pre>

Here are the gists of the files.

**defaults/main.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 defaults-main.yml %}

**handlers/main.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 ssh-handlers-main.yml %}

**handlers/Ubuntu14.04.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 ssh-handlers-ubuntu.yml %}

**tasks/main.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 ssh-tasks-main.yml %}

**tasks/Ubuntu14.04.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 ssh-tasks-ubuntu.yml %}

**vars/Ubuntu14.04.yml**

{% gist fishi0x01/6a1a139e821af26e8d2bbfb71a7b37c2 vars-ubuntu.yml %}

In that way we separated OS specific variables in dedicated files inside the `vars` directory. 
Also OS specific tasks and handlers can now easily be separated. 
Ansible detects the OS it operates on and includes the dedicated files.


[ansible-galaxy]: https://galaxy.ansible.com/
[ansible-debops]: https://github.com/debops
