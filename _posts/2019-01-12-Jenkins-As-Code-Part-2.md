---
layout: post
title: "Jenkins-as-Code Part II | Configuration"
date: 2019-01-12 14:30:00 +0000
modified: 2019-03-10 12:00:00 +0000 
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
leverage the configuration as code plugin and configuration scripts 
in a central Github repository which are executed by a Jenkins pipeline.
<!--more-->

In the [previous part][part-one] of this series we created a Jenkins 
docker image with a baked in configuration pipeline.  
We now focus on the components of that pipeline, i.e., 
running the [CasC][vocabular-casc] plugin, 
executing [configuration scripts][vocabular-configuration-script] 
and [seeding][vocabular-seeding] job interfaces. 
The complete code can be found in this [demo repo][jenkins-as-code-github-repo].

## Directory Layout

Lets quickly remind ourselves about the layout of our shared library repository.

```
shared-library
|-- resources
|   |-- config
|   |   |-- configuration-as-code-plugin
|   |   |   `-- jenkins.yaml
|   |   `-- groovy
|   |       |-- timezone.groovy
|   |       |-- triggerConfigurationAsCodePlugin.groovy
|   |       `-- userPublicKeys.groovy
|   |-- init
|   |   `-- ConfigurationAndSeedingPipeline.groovy
|   `-- jobDSL
`-- vars
```

The majority of Jenkins can be configured using CasC, but there are a few things 
which do still require groovy system configuration scripts, like setting the timezone. 

## Configuration as Code Plugin

Configuring Jenkins with groovy scripts can be tedious. 
You have to go through the plugin's code, find the constructor and 
properly use it in groovy code in order to configure it. 

However, in 2018 a new approach arised in the form of a plugin. 
It is called the [configuration-as-code plugin][plugin-configuration-as-code] (CasC). 
The goal of this plugin is to describe your jenkins configuration in simple `.yaml` files. 

The following CasC file configures Security, GitHub, OAuth, Slack, Themes, Agents and Authorizations:

**jenkins.yaml:**
{% gist fishi0x01/63ce90a4e5b24aa0297aa69622d8ca8f jenkins.yaml %}

Secrets are described as `${secret}`. As of writing this article, secrets in CasC can be loaded 
from environment variables, files or [HashiCorp Vault][hashi-vault] paths. 
In this post's [demo repo][jenkins-as-code-github-repo] we use files as secret sources. 
The path to the secret files is pre-baked in the Dockerfile as `ENV SECRETS="/var/jenkins_home/"`. 
A secret like `${jenkins-ssh-keys/ssh-agent-access-key}` is then loaded from CasC at
`/var/jenkins_home/jenkins-ssh-keys/ssh-agent-access-key`. 
However, I am a big fan of HashiCorp's Vault. Whenever possible, I use it as a secret source, but 
that is out of scope of this blog post. To setup CasC with Vault, consult their [README][casc-readme]. 

## Configuration Scripts

CasC does the heavy lifting of our configuration work. However, there are some aspects that still 
need some groovy scripting magic. 

### Timezone

Obviously a proper timezone setting is nice in order to not be confused by the build times.

**timezone.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 timezone.groovy %}

### User Public Keys

We can add public keys for users.

**user-public-keys.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 userPublicKeys.groovy %}

Adding a public key to a user is useful if you must interact with jenkins via [jenkins-cli][jenkins-cli]. 
In my experience Jenkins CLI works best when used with the `-ssh` option. 

### Others

Over the time I gathered more configuration scripts, e.g., GitHub OAuth or Slack configuration. 
Thanks to CasC I do not need them anylonger. However, I keep the collection in a 
[gist][gist-config]. Maybe it will still be of help to someone out there. 

## Summary

We now have a fully configured Jenkins. 
The configuration is part of our shared library. 
The configuration is executed via a single pre-baked configuration and seeding pipeline 
which uses our shared library. 
We can change a configuration by pushing the change to the shared library and running 
the pre-baked configuration and seeding pipeline in Jenkins. 

In the [next part][next-part] of this series we will have a quick look at Jenkins JobDSL plugin for job interfaces as-code.

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
[vocabular-casc]: /weblog/2019/01/06/jenkins-as-code-part-1/#casc
[part-one]: /weblog/2019/01/06/jenkins-as-code-part-1/
[jenkins-cli]: https://jenkins.io/doc/book/managing/cli/
[next-part]: /weblog/2019/02/09/jenkins-as-code-part-3/
[gist-config]: https://gist.github.com/fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76
[hashi-vault]: https://www.vaultproject.io/
[jenkins-as-code-github-repo]: https://github.com/devtail/jenkins-as-code
[casc-readme]: https://github.com/jenkinsci/configuration-as-code-plugin
