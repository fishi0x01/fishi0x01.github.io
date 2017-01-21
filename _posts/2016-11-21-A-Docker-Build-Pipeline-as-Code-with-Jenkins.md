---
layout: post
title: "A Docker Build Pipeline as Code with Jenkins"
date: 2016-11-21 19:25:09 +0000
modified: 2017-01-21 13:12:05 +0000 
comments: true
disqus_id: 13
permalink: weblog/2016/11/20/docker-build-pipeline-as-code-jenkins/
redirect_from:
  - /weblog/E/
categories: jenkins docker build-pipeline groovy
---


Since quite some time now we are no longer satisfied with only having our App Layer as code in repositories, but we also want every other component of our system codified. 
After [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_Code) (e.g., [Terraform](https://www.terraform.io/)) and Configuration as Code a.k.a. [Continuous Configuration Automation](https://en.wikipedia.org/wiki/Continuous_configuration_automation) (e.g., [Ansible](https://www.ansible.com/) and [SaltStack](https://saltstack.com/)) approaches, we also 
want our automation itself codified: Pipeline as Code!<!--more-->
Some of the big advantages of managing system components in code are:

* It is easier for teams to work on the same complex components if they are managed in code repositories
* Each aspect of your system can be versionized
* Codified components can be easier used for further automation

External CI providers such as [Travis](https://travis-ci.org/) or [Circle CI](https://circleci.com/) made the Pipeline as Code principle very popular - especially amongst OSS Projects.
Nevertheless, external CI providers may not support all of your Pipeline needs and even more important: A Pipeline may contain information you do not want to share with external providers. 
Personally, I pretty much trust the guys from Travis and for OSS projects they are way to go (not saying no to free checks and badges!), but if they get compromised the Pipeline data is exposed. 
Beginning with version 2, [Jenkins finally supports the Pipeline as Code approach](https://jenkins.io/solutions/pipeline/) with the `Jenkinsfile`, which brings our Pipeline back into our own hands. 
In this post I want to outline how to build a simple codified Pipeline in Jenkins to containerize a Java project with Docker. 
I will solely focus on the Pipeline code. No Maven/Java code examples will be given here.
 

## Setup Assumptions ##

I am assuming that you have a Maven Project which builds `target/project.war` via `mvn clean package -U`. 

I also assume that you have a running Jenkins 2.x with access to a Docker Daemon (locally or remote). 
In case you are running Jenkins inside a container, you have to give it access to a Docker Daemon socket, either by sharing 
the docker hosts socket with the container or by using a remote server. 
<!-- TODO: post about this issue -->

Jenkins must have read access to your code repository (which can easily be established using [deploy keys](https://developer.github.com/guides/managing-deploy-keys/)). 

Jenkins must have Maven configured as a global tool referenced as `M3`.

Further, we need the following Jenkins plugins installed:

* [Slack Notification](https://wiki.jenkins-ci.org/display/JENKINS/Slack+Plugin)
* [Docker Pipeline](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Pipeline+Plugin)

<!-- TODO: Post about how to bootstrap a Jenkins setup like that with Groovy scripts -->

## The Jenkins Docker Pipeline ##

For our Java project, let us build a pipeline which handles the following steps:

* Checkout a branch from a SCM
* Set a branch SNAPSHOT version inside the pom file
* Build a .war package for the checked out branch
* Build a docker image containing this .war package
* Send notifications to a Slack channel

To get started, we first create a `build.groovy` file inside our Java code repository, ideally on a new branch, which we call `jenkins`. 

{% include tags/hint-start.html %}
**NOTE:** Some Plugins, such as the [Multibranch Pipeline Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Pipeline+Multibranch+Plugin) 
require that the pipeline code is in a single file called `Jenkinsfile` in the repositorie's root. 
{% include tags/hint-end.html %}

The reason why we put the `build.groovy` on a separate branch is to decouple the app code from the pipeline code. 
Imagine you want to build a feature branch, but something in your pipeline changed. 
You would need to push a new commit with that pipeline change on the feature branch. 
This is especially bad, if you want to build a specific commit, e.g., a tag, since that would require you to re-tag. 
On the other hand this approach adds more complexity to your project, as an extra branch for pipelines may not be 
as intuitive as keeping the pipeline defintions with the rest of your code in the same branch. 
A better approach would be to use the [Multibranch Pipeline Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Pipeline+Multibranch+Plugin), also because it 
is a requirement to get the most out of the new Jenkins UI [Blue Ocean](https://wiki.jenkins-ci.org/display/JENKINS/Blue+Ocean+Plugin).
However, in this post we are satisfied with a separate branch. 
The repositorie's dir structure may now look something like this:

```
project/
├── .jenkins
│   └── build.groovy
├── pom.xml
└── src
```

Initially, the `build.groovy` script may contain the following for testing purposes:

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 initial-test-build.groovy %}

Now, we create a Jenkins Pipeline job, which checks out the `jenkins` branch of our project and looks 
for the pipeline file `.jenkins/build.groovy`. The configuration may look something like this:

<img src="/content-images/jenkins-pipeline-job.png" alt="Jenkins Pipeline Job" style="display: block; margin-left: auto; margin-right: auto;">

When we run this job, it should print `The pipeline started` in the job's console output.

In a next step, we want to build a SNAPSHOT package of a branch. 
The branch is given as an input variable named `BRANCH_NAME`. 
It can be given to the job as a simple String input parameter or by using the [Git Parameter Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Git+Parameter+Plugin) and 
is referenced inside the pipeline script as `env.BRANCH_NAME`. 
We want our branch SNAPSHOTs to have the following version naming pattern: `<version>-<branchName>-SNAPSHOT`, where `<version>` is taken from the checked out `pom.xml` 
and `branchName` is given as an input parameter `env.BRANCH_NAME`. 

Let's extend our pipeline script to checkout and build the specified branch:

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 java-build.groovy %}

This pipeline checks out the specified branch, determines and sets the proper branch snapshot version inside the `pom.xml` 
and finally builds the .war file. 
Next, we move on to packaging our .war inside a Tomcat docker image. 
We create a docker build context in our project's `jenkins` branch, which will give us the following directory structure:

```
project/
├── .docker
│   └── build
│       ├── docker-entrypoint.sh
│       └── Dockerfile
├── .jenkins
│   └── build.groovy
├── pom.xml
└── src
```

The `Dockerfile` and `docker-entrypoint.sh` may contain the following:

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 Dockerfile %}

{% include tags/hint-start.html %}
**IMPORTANT:** By default the resulting container will run as `root`. This should be avoided if possible, since the `root` 
user inside the container has the same uuid as the host's `root` user, which is potentially dangerous in case the container gets compromised. 
{% include tags/hint-end.html %}

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 docker-entrypoint.sh %}

The `docker-entrypoint.sh` allows our container to be configured via environment variables, making it more flexible to run in different environments. 
Further, we adjust our `build.groovy` script to build and push a functional docker image:

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 docker-build.groovy %}

{% include tags/hint-start.html %}
Note, that we also adjusted the `Checkout` stage, to copy the docker build context to another location before we switch branches (the build context might not be available on the new branch).
Also, this pipeline does not contain important aspects such as testing or uploading of the .war file to a java package manager like [Artifactory](https://www.jfrog.com/open-source/).
{% include tags/hint-end.html %}

`withDockerServer` and `withDockerRegistry` are built-in wrappers by Jenkins' [docker-plugin](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin) 
and allow us to use a remote host to build the docker image (very handy when running the Jenkins master inside a container itself) and to 
define a custom private docker registry (most likely you do not store your companie's docker images on dockerhub).

Finally, let us add some visibility to our build by sending the build status to a slack channel. 
We slightly modify our `build.groovy`:

{% gist fishi0x01/9c8d39d7a79cbe454f87c4745897d561 slack-build.groovy %}

That's it! We now have a Pipeline which handles our Docker image builds for specific branches and sends the results to a Slack channel. 
In a future post I will show how to share Groovy libraries between Jenkins jobs to apply the [DRY principle](https://en.wikipedia.org/wiki/Don't_repeat_yourself) to your Pipeline code.


