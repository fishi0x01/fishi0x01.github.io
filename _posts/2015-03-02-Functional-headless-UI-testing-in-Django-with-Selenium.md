---
layout: post
title:  "Functional headless UI testing in Django with Selenium"
date:   2015-03-02 23:43:47 +0000
modified: 2015-06-18 02:04:03 +0000 
comments: true
disqus_id: 6
permalink: weblog/2015/03/02/functional-headless-ui-testing-django-selenium/
categories: ci django python
---

After [setting up a basic Django CI][fishi-django-ci] for standard unit tests in my last post, I now also wanted to add functional UI tests with [Selenium][selenium] to my testing procedure. 
That's why in this post I want to cover how to setup a headless functional test environment for Django projects on a Debian 7 server. 
In the end of this post we will also see a simple Django UI test case example.<!--more-->
{: .text-justify}

### Installing Firefox on Debian 7 ###

Of course, in a first step we need to install a web browser with which we can run our functional tests. 
I decided to use Firefox. 
Since Debian 7 supports Iceweasel, installing Firefox requires a little extra work. 
One way is to add `deb http://packages.linuxmint.com debian import` to `/etc/apt/source.list` and to import the necessary GPG keys. 
How this can be done is explained [here][debian-ff].
{: .text-justify}

### Installing Virtual Displays ###

Most servers do not have a display - so in order to start a browser and run UI tests, in a next step we have to install a virtual display environment. 
For this purpose we can install [xvfb][xvfb]: 
{: .text-justify}

{% include tags/shell-start.html %}
$ sudo apt-get install xvfb
{% include tags/shell-end.html %}

xvfb can then be used to start a virtual display in which we can run our browser window. 
{: .text-justify}

Now we also need a way to start xvfb from within our test. 
[PyVirtualDisplay][py-virt-disp] is a wrapper for xvfb, which makes it easy for us to create a virtual display inside our python code. 
It can be simply installed via pip (preferably inside your virtual python environment):
{: .text-justify}

{% include tags/shell-start.html %}
(py-env)$ pip install pyvirtualdisplay
{% include tags/shell-end.html %}

{% include tags/hint-start.html %}
I strongly recommend the use of [virtual python environments](http://docs.python-guide.org/en/latest/dev/virtualenvs/) when working with Django. 
These can save you from a lot of trouble in case you are having multiple projects on the same server - especially when upgrades and migrations are coming closer!
{: .text-justify}
{% include tags/hint-end.html %}

At the end of this post I show a test case in which a virtual display with the help of PyVirtualDisplay is created. 
{: .text-justify}

### Installing Selenium ###

I've had very good experiences with Selenium in the past. 
It has a great community and quick fixes for new browser versions. 
Lucky for us, Selenium also comes for Python and can be installed via pip: 
{: .text-justify}

{% include tags/shell-start.html %}
(py-env)$ pip install selenium
{% include tags/shell-end.html %}

### An Example Test ###

Now that we have everything installed/setup, lets take a look at a very basic "Hello World!" example test case for a basic html test website, which is returned when calling /test/example on our Django server. 
{: .text-justify}

{% gist fishi0x01/c879b5d110b32ea18282 example.html %}

{% gist fishi0x01/c879b5d110b32ea18282 test_functional_example.py %}

We first create a virtual display with dimension 1024x786. 
Next, we use the Selenium Firefox webdriver and open our test website. 
After this, we try to fetch the element with the id `test`, retrieve its text and verify that it is indeed "Hello World!". 
When the test finishes, we tear down the browser and the virtual display. Yep, it's that easy!
{: .text-justify}

{% include tags/hint-start.html %}
I use Django's `@skipIf` tag in order to easily disable functional UI tests. 
As we could see, functional UI tests require extra packages and a specific browser. 
In case you only want to test those on the CI server you have to set inside the CI's project's `settings.py`: `SKIP_FUNCTIONAL_TESTS = False`. 
The Developer's client on the other hand could easily disable the functional tests by not setting `SKIP_FUNCTIONAL_TESTS` at all in his local project's `settings.py`. 
Thus, on a local dev client one could easily exclude functional tests and only perform unit tests. 
{: .text-justify}
{% include tags/hint-end.html %}

That's it! 
We are now able to easily write UI tests. 
For embedding your tests in a CI process, please refer to my previous post on how to [setup a Django CI with Git and Jenkins][fishi-django-ci]. 
{: .text-justify}

Happy UI testing!

[fishi-django-ci]: /weblog/2015/02/22/setting-django-ci-jenkins-and-git/
[selenium]: http://www.seleniumhq.org/
[debian-ff]: http://superuser.com/questions/322376/how-to-install-the-real-firefox-on-debian
[xvfb]: http://en.wikipedia.org/wiki/Xvfb
[py-virt-disp]: https://pypi.python.org/pypi/PyVirtualDisplay
