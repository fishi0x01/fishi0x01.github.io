---
layout: post
title: "Jenkins-as-Code Part II | Configuration"
date: 2019-01-12 14:30:00 +0000
modified: 2019-01-12 14:30:00 +0000 
comments: true
disqus_id: 16
permalink: weblog/2019/01/12/jenkins-as-code-part-2/
redirect_from:
  - /weblog/11/
categories: jenkins
---

This is the 2nd part of the Jenkins-as-Code series. 
In this part we will focus on configuring Jenkins through code. 
The goal is to avoid manual configuration in the UI and instead 
leverage configuration scripts in a central Github repository which 
are executed by a Jenkins pipeline.
<!--more-->

In the [previous part][part-one] of this series we created a Jenkins 
docker image with a baked in pipeline for executing 
[configuration scripts][vocabular-configuration-script] and [seeding][vocabular-seeding]. 
We now focus on those configuration scripts. 

## Directory Layout

Lets quickly remind ourselves about the layout of our shared library repository.

```
shared-library
├── resources
│   ├── config
│   │   ├── auth.groovy
│   │   ├── credentials.groovy
│   │   ├── slack.groovy
│   │   ├── theme.groovy
│   │   ├── sshd.groovy
│   │   ├── github.groovy
│   │   ├── timezone.groovy
│   │   ├── baseURL.groovy
│   │   ├── globalEnvVars.groovy
│   │   ├── globalSharedLibrary.groovy
│   │   └── slaves.groovy
│   ├── init
│   │   └── ConfigurationAndSeedingPipeline.groovy
│   └── jobDSL
└── vars
```

The configuration scripts reside in `resources/config`. 

## Secrets - Setting Credentials in Jenkins

In most cases Jenkins needs credentials such as ssh keys (e.g., deploy keys) or 
secret IDs (e.g., ClientID and ClientSecret from OAuth Apps). 
We can mount the credentials as files into our docker container, but we still need 
to read them into the internal Jenkins credential store. 

**credentials.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 credentials.groovy %}

The above script adds Slack, Github CI User and HashiCorp Vault tokens from local files 
into Jenkins. 
Further, it adds user/password credentials for the dockerhub and Github CI user from 
local files into Jenkins. 
Last but not least, it adds SSH private keys for a service repository and slave nodes from local 
files into Jenkins. 

## Authentication - Configuring Access to Jenkins

Jenkins is a powerful part of our infrastructure. 
We build and deploy services with it, so we want to limit access. 
As we host our [shared libray][vocabular-shared-library] on Github we could use 
[Github OAuth][github-oauth] to easily authenticate users. 
In order for that to work we first need to setup an OAuth Application 
for our Github organization at https://github.com/organizations/\<my-org\>/settings/applications.
This will give us a `client_id` and a `client_secret`, which we have to pass to Jenkins
in order to connect with Github to verify the user's identity.

**githubOAuth.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 githubOAuth.groovy %}

The above script configures the [Github OAuth Plugin][plugin-github-oauth] and 
gives admin permissions to user `fishi0x01` and the members of the 
Github team `my_team_name`.

## Configuring the Global Shared Library

A [global shared library][global-shared-library] is usable by every job by adding a simple 
`@Pipeline('<lib-name>')` annotation (to the `Jenkinsfile`). 

**globalSharedLibrary.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 globalSharedLibrary.groovy %}

The above script configures `git@github.com:<my-org>/<my-shared-library>.git` as a global 
shared library which can be used by every job. 

## Some General Settings

Lets continue with the configuration of some convenient plugins.

#### Theme

Lets spice up our Jenkins with a custom UI. 
We can use the [Simple Theme Plugin][plugin-simple-theme] for that. 
Further, we can use [Afonso F's theme generator][theme-generator] to create a valid 
Jenkins `.css` file for this plugin. 
We should place the generated `.css` file in the `userContent` directory of Jenkins 
in order to be publicly available.

**theme.groovy**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 theme.groovy %}

The above script configures the simple theme plugin to use our generated `.css` file.

#### Slack

It is nice to get deploy or build messages send directly to slack.

**slack.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 slack.groovy %}

The above script configures the slack plugin. 
This enables us to use `slackSend` calls in our pipelines.

#### Base URL

The base URL setting is very important as it is used to generate the URLs within Jenkins.

**baseURL.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 baseURL.groovy %}

The above script configures the base URL to our domain.

#### Timezone

Obviously a proper timezone setting is nice in order to not be confused by the build times.

**timezone.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 timezone.groovy %}

#### GitHub

[MultiBranch Pipelines][multibranch-pipeline] are a nice way to build projects. 
However, they do not work with classic deploy keys. 
If you host your projects on Github, then an easy way to get your multibranch pipelines 
running is by using the [Github Plugin][plugin-github].

**github.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 github.groovy %}

The above script configures the Github Plugin to connect to Github with a CI user's token. 
Of course you have to create that CI user first and give it access to your Github organization. 

#### SSHD

The SSHD setting might become important for you if you try to trigger jobs from the command 
line on the jenkins master. We will need it in a later part of this series when we try 
to create a pipeline to bootstrap slaves in different cloud providers.

**sshd.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 sshd.groovy %}

The above script configures the SSHD port of the Jenkins master.

#### Global Environment Variables

Global environment variables are visible to every build. 
That way some general settings can be made visible to all pipelines.

**globalEnvVars.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 globalEnvVars.groovy %}

The above script configures global environment variables.

## The Future: Configuration As Code Plugin

Configuring Jenkins with groovy scripts can be tedious. 
You have to go through the plugin's code, find the constructor and 
properly use it in groovy code in order to configure it. 

However, in 2018 a new approach arised in the form of a plugin. 
It is called the [configuration-as-code plugin][plugin-configuration-as-code]. 
The goal of this plugin is to describe your jenkins configuration in a single `.yml` 
file. The idea looks very promising. 
I haven't used this plugin yet, but it seems it reached a rather mature status in 
September 2018. I recently stopped working on Jenkins topics in order to 
focus on Information Security Engineering, but once I get back to Jenkins one day 
I will definitely also have a look at that plugin. Maybe I will also write a blog 
post about it. 

## Summary

We now have a fully configured Jenkins. 
The configuration is part of our shared library. 
The configuration is executed via a single pre-baked configuration and seeding pipeline 
which uses our shared library. 
We can change a configuration by pushing the change to the shared library and running 
the pre-baked configuration and seeding pipeline in Jenkins. 

In the next part of this series we will have a look at managing slaves on demand in multiple 
cloud providers at the same time.

[plugin-configuration-as-code]: https://plugins.jenkins.io/configuration-as-code
[plugin-github-oauth]: https://plugins.jenkins.io/github-oauth
[plugin-simple-theme]: https://plugins.jenkins.io/simple-theme-plugin
[plugin-github]: https://plugins.jenkins.io/github
[multibranch-pipeline]: https://jenkins.io/doc/book/pipeline/multibranch/
[theme-generator]: http://afonsof.com/jenkins-material-theme/
[github-oauth]: https://developer.github.com/apps/building-oauth-apps/authorizing-oauth-apps/
[vocabular-shared-library]: https://jenkins.io/doc/book/pipeline/shared-libraries/
[global-shared-library]: https://jenkins.io/doc/book/pipeline/shared-libraries/#global-shared-libraries
[vocabular-configuration-script]: /weblog/2019/01/06/jenkins-as-code-part-1/#configuration-script
[vocabular-seeding]: /weblog/2019/01/06/jenkins-as-code-part-1/#seeding
[part-one]: /weblog/2019/01/06/jenkins-as-code-part-1/
