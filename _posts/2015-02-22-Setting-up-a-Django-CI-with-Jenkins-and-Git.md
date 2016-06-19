---
layout: post
title:  "Setting up a Django CI with Jenkins and Git"
date:   2015-02-22 19:20:48 +0000
modified: 2015-06-18 02:03:11 +0000 
comments: true
permalink: weblog/2015/02/22/setting-django-ci-jenkins-and-git
redirect_from:
  - /weblog/6/
categories: ci django git
---

After experimenting with [Django][django-project] for a while now, I decided that it is time for a Continous Integration for Django on my server in order to start some long-term projects. 
This is why in this post I will describe how to setup [Jenkins][jenkins-project] for Django projects on Debian servers to detect changes to a Git repository, run tests in case of changes and deploy them on your Apache Server.<!--more-->

I assume we have a Django project `d_project` at `/srv/www/django/d_project` running in a virtual environment at `/srv/www/django/d_project/py-env`. 

{% include tags/hint-start.html %}
I strongly recommend the use of [virtual python environments](http://docs.python-guide.org/en/latest/dev/virtualenvs/) when working with Django. 
These can save you from a lot of trouble in case you are having multiple projects on the same server - especially when upgrades and migrations are coming closer!
{% include tags/hint-end.html %}

### Installing Jenkins ###
There are different ways to [install Jenkins][jenkins-install]; here are 2 examples: 

* You could register the Jenkins repository in your package manager and install it
* Since I already have a running Tomcat, I decided to download the [latest jenkins war][jenkins-latest] and deploy it in my Tomcat server instead

Consequently, since Jenkins is running within my Tomcat, the Jenkins user is - and in the following I will also assume that it is - `tomcat`.

{% include tags/hint-start.html %}
Please make sure to [secure Jenkins](https://wiki.jenkins-ci.org/display/JENKINS/Securing+Jenkins), especially if it is accessible via Internet!
{% include tags/hint-end.html %}

### Apache Configuration ###
Most likely you will run your Jenkins/Tomcat server behind an Apache Server or something similar. 
If Jenkins is running behind Apache, please ensure that your Proxy settings are correct. 
Here an example proxy configuration snippet for your Apache 2.x Virtual Host file: 

{% gist fishi0x01/719c2aaab47709bb7d02 jenkins-vhost.apacheconf%}

Further, Django projects can be hosted via Apache with [mod_wsgi][modwsgi]. 

**Virtual Host File**

{% gist fishi0x01/719c2aaab47709bb7d02 django-vhost.apacheconf %}

### Optional - Enable Coverage Reports ###
In case you want to use coverage reports, please install [Violations][jenkins-violations] and [Cobertura][jenkins-cobertura] Plugin in Jenkins with the help of its Plugin Manager. 
Also, you will need [django-jenkins][django-jenkins] and coverage for your python environment:

{% include tags/shell-start.html %}
(py-env)$ pip install django-jenkins
(py-env)$ pip install coverage
{% include tags/shell-end.html %}

In order to use django-jenkins for your project, you have to add `django_jenkins` to your project's `INSTALLED_APPS`. 
From then on you can execute tests using `python manage.py jenkins` or (with coverage reports) `python manage.py jenkins --enable-coverage`.

Also, you can define in your project's `settings.py` which Apps should be tested by the jenkins runner by simply adding them to `PROJECT_APPS`.

### Optional - Install Cleanup Plugin ###
I use Jenkins' [Workspace Cleanup Plugin][jenkins-cleanup] to ensure that some files always get deleted before a new build starts. 
This is especially useful, if you only want a subset of files to be deleted/refreshed for sure. 
The Plugin can of course be installed via the Jenkins Plugin Manager. 
After the installation, inside each project configuration tab, you now have the option to activate a workspace sweep and define patterns. 

### Git ###
For Jenkins to handle Git repositories, you first have to install the [GIT plugin][jenkins-git]. 
Of course you will also need Git available on your server and there are different ways to achieve that... 
 
One efficient way to manage self-hosted Git repositories is [gitolite][gitolite]. 
I like to use gitolite in combination with [redmine][redmine] and the [redmine_git_hosting plugin][redmine-git]. 
In case you use the same setup, you could do the following to enable Jenkins access to your repositories: 

* Create a `Jenkins CI` user in redmine and give him read/write permissions to repositories.
* [Create a public RSA key][git-ssh] for the Jenkins user in `$JENKINS_HOME/.ssh/` and save it in the redmine_git_hosting plugin. 
Be sure to **NOT** use a passphrase for the key, since otherwise Jenkins will be asked to enter the password each time he tries to access the repository.
* Make sure that your Git server is in the known_hosts list of your jenkins user. 
If not, you can manually use Git and you will be asked whether to add the server to the known_hosts list or not. 
From then on your jenkins user will be able to access the repository.
* Now, in redmine you can just add the `Jenkins CI` user to any project in which you need a CI.

{% include tags/hint-start.html %}
No matter which Git server/management tool you are using, in any case you need to ensure, that the jenkins user has read permissions to the repositories. 
If you want Jenkins to merge branches after successful builds/tests, you also need to enable write permissions to the repositories.
{% include tags/hint-end.html %}

### Allowing Jenkins to restart Apache ###
Before we start here, please note that a publicly accessible dev version might lead to security issues! 

In case you want Jenkins to also deploy your commit, it has to be allowed to restart Apache, so Apache can detect the changes to the code base. 
Add the following to your sudoers file: 

{% highlight Kconf %}
tomcat ALL=NOPASSWD: /usr/sbin/apachectl
{% endhighlight %}

This enables our Jenkins user `tomcat` to have root access to `apachectl`. 

{% include tags/hint-start.html %}
Due to security reasons, I recommend to only automatically deploy dev versions on your server if they are not publicly accessible, because dev versions tend to have severe bugs which may put your server in danger! 
If you only want to deploy your Django project for testing purposes, I recommend to simply rely on Django's built-in test framework, without deploying your project with Apache or a similar server. 
{% include tags/hint-end.html %}

### Creating a new build job ###
In your Jenkins UI: 

**1. Create a new job**

* Select **New Item**
* Specify build name and choose **Freestyle project**

**2. Configure the job**

* Under **Advanced Project Options** select **Advanced** and define check **Use custom workspace**
* Define the workspace to be `/srv/www/django/d_project`
* In **Source Code Management** select **Git** and define the repository URL (in case you use redmine with the git_hosting_plugin, this can be found in the Overview of your redmine project). 
Also, you can specify the branches to build - for a more sophisticated git project structure this is very important, but in this post we will simply build the master branch.
* In **Build Triggers** select **Poll SCM** and define a schedule such as `H/30 * * * *`. 
This will let Jenkins poll the repository every 30 minutes.
{% include tags/hint-start.html %}
If you do not like polling, you can also activate **Trigger builds remotely (e.g., from scripts)**, define an authentication token and use Git commit hooks to trigger the resulting build URL whenever a commit to the repository is done.
{% include tags/hint-end.html %}

* In **Build**, specify a command to run the build/deploy script (e.g. `/srv/www/django/deploy.sh`)

### Build/Deploy Script ###

The deploy.sh could look something like this:

{% gist fishi0x01/719c2aaab47709bb7d02 deploy.sh %}

Basically this script installs the project's requirements, migrates model changes, lets Apache reload the source files and runs the tests. 

{% include tags/hint-start.html %}
This is a very basic introduction to a Django CI. 
I recommend a more complex Git branching structure and consequently also a more sophisticated Jenkins branch build configuration for projects involving more than one person. 
You can configure Jenkins to automatically merge branches whenever a branch passes the build/deploy script without errors - thus you could keep your `dev` branch clean since bugs that do not pass your test suits do not get merged. 
{% include tags/hint-end.html %}

That's it! We now got a working basic Django CI! Happy integrating!


[django-project]: https://www.djangoproject.com/
[jenkins-project]: https://jenkins.io/
[jenkins-install]: https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins
[jenkins-latest]: http://mirrors.jenkins-ci.org/war/latest/jenkins.war
[modwsgi]: https://code.google.com/p/modwsgi/
[jenkins-violations]: http://wiki.jenkins-ci.org/display/JENKINS/Violations
[jenkins-cobertura]: http://wiki.jenkins-ci.org/display/JENKINS/Cobertura+Plugin
[django-jenkins]: https://sites.google.com/site/kmmbvnr/home/django-jenkins-tutorial
[jenkins-cleanup]: https://wiki.jenkins-ci.org/display/JENKINS/Workspace+Cleanup+Plugin
[jenkins-git]: http://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
[gitolite]: http://gitolite.com/gitolite/index.html
[redmine]: http://www.redmine.org/
[redmine-git]: http://www.redmine.org/plugins/redmine_git_hosting
[git-ssh]: https://help.github.com/articles/generating-ssh-keys/
