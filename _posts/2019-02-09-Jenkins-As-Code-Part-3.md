---
layout: post
title: "Jenkins-as-Code Part III | JobDSL"
date: 2019-02-09 10:30:00 +0000
modified: 2019-02-09 10:30:00 +0000 
comments: true
disqus_id: 17
permalink: weblog/2019/02/09/jenkins-as-code-part-3/
redirect_from:
  - /weblog/12/
categories: jenkins
---

The 3rd part of the Jenkins-as-Code series focuses on the automated creation of [job interfaces][vocabular-job-interface]. 
That could be achieved with pure groovy scripting as used in the [previous part][previous-part]. 
However, the [JobDSL plugin][job-dsl-plugin] offers a more convenient and clean way, so we will focus on that. 
<!--more-->

There are already quite a lot of tutorials and code snippets about the JobDSL plugin all over the web, so this will be a rather short post. 
I post this merely for the sake of completion as without JobDSL, Jenkins is not fully as-code.

## JobDSL Introduction

JobDSL is a DSL language on top of groovy. 
It offers an easy way to describe job interfaces as-code. 
It is very common to have a job interface seeding pipeline, which pulls the jobDSL code from a repository and provisions the job interfaces. 
Jenkins jobDSL is very easy to understand and write. 
It is easy to pickup as it comes with a [good documentation][job-dsl-public-doc]. 
However, jobDSL can only provision features of plugins that are already installed in your jenkins instance. 
So the online documentation might show you features which are not available to your jenkins instance because of missing plugins. 
You can find all available features documented on your jenkins instance at `${JENKINS_BASE_URL}/plugin/job-dsl/api-viewer/index.html`.

Further, there is an online [playground for jobDSL][job-dsl-playground] scripts. 
It translates your scripts to the final xml of the job interface, so it is ideal to quickly validate your scripts during jobDSL development. 

## Multibranch Build Pipelines

After all that praise, now let's have a look at some code. 
In the following we create a set of Multibranch Pipelines for project repositories on Github: 

**multibranchJobs.groovy:**
{% gist fishi0x01/4ac66ebeb096c163b03d46bc1e2ec89b multibranchJobs.groovy %}

We assume that Jenkins is already hooked up with Github, which is a requirement for a Github Multibranch pipeline to function. 

{% include tags/hint-start.html %}
Hooking up your Jenkins instance with Github and setting up credentials for CI users can be done fully as-code as well, as we have seen in the [previous part][previous-part] of this series. 
{% include tags/hint-end.html %}

A seed pipeline to trigger the jobDSL could look like that:

**seedPipeline.groovy:**
{% gist fishi0x01/4ac66ebeb096c163b03d46bc1e2ec89b seedPipeline.groovy %}

{% include tags/hint-start.html %}
This is a very simplified seeding pipeline. In the [previous part][previous-part] of this series we covered a more mature configuration and seeding pipeline. 
{% include tags/hint-end.html %}

## Conclusion

This short post gave a quick overview of the JobDSL plugin and how to use it. 
We created a simple DSL for multibranch pipeline job interfaces of different projects hosted on Github. 

[job-dsl-plugin]: https://plugins.jenkins.io/job-dsl
[vocabular-job-interface]: /weblog/2019/01/06/jenkins-as-code-part-1/#job-interface 
[previous-part]: /weblog/2019/01/12/jenkins-as-code-part-2/
[job-dsl-public-doc]: https://jenkinsci.github.io/job-dsl-plugin/
[job-dsl-playground]: http://job-dsl.herokuapp.com/
