---
layout: post
title: "Jenkins-as-Code Part I | Initial Setup"
date: 2019-01-06 14:45:00 +0000
modified: 2019-03-30 10:00:00 +0000
comments: true
disqus_id: 15
permalink: weblog/2019/01/06/jenkins-as-code-part-1/
categories: jenkins
---

This is the beginning of a series about full Jenkins automation.
I am calling that approach [jenkins-as-code](#jenkins-as-code).
The goal is to configure every aspect of Jenkins and its pipelines from a central git repository.
We will leverage groovy scripting, jobDSL and [shared libraries][shared-libraries] to not only codify the build/deploy pipelines ([pipeline-as-code][pipeline-as-code]), but to also bootstrap and configure Jenkins from scratch (e.g., credentials, authorization, theme and job setup).
{: .text-justify}
<!--more-->

The following demo shows what we have at the end of this series:
{: .text-justify}

<br/>
<img src="/content-images/jenkins-bootstrap-700px.gif" alt="Demo" style="display: block; margin-left: auto; margin-right: auto;">
<br/>

Every aspect of what is shown here can be found in full context in the [jenkins-as-code Github repository][jenkins-as-code-github-repo].
{: .text-justify}

It is usually a good idea to have as much as possible setup in an \*-as-code approach, because it offers:
- clear definitions and automation, i.e., clear state definition and reproducibility
- rollouts from central servers (offers audit logs)
- common software development workflows, i.e., testing, reviewing and rollouts are easier to manage
{: .text-justify}

Since Jenkins 2.x we can use pipeline-as-code approaches like [Travis][travis] or [CircleCI][circleci] do.
However, the overall (plugin) [configuration](#configuration-script) and setup of [job interfaces](#job-interface) is not covered by pipeline-as-code.
For a complete jenkins-as-code approach we also want our configuration and
job interfaces treated as-code and be able to rollout any changes dynamically through a jenkins job
interface without the need to restart Jenkins.
{: .text-justify}

In the first part of this series we will discuss the basics:
- What are the layers in jenkins-as-code?
- What are the relations between those layers?
{: .text-justify}

Next, we will create a Jenkins docker image packaged with a configuration/seeding job interface and pipeline definition, which uses a central shared library from GitHub to rollout configuration and [seeding](#seeding) changes.
Finally, we will have a closer look at contents of that central shared library.
{: .text-justify}

## Layers and Terminology

In order to avoid confusion it is very important to define the different layers and terms which will be used throughout this series.
{: .text-justify}

#### Jenkins-as-Code
Jenkins-as-code describes an approach to codify and automate every layer of Jenkins.
In order to achieve its goal the approach leverages jobDSL, configuration and pipeline definition scripts.
{: .text-justify}

#### Job Interface
A job interface describes the job in the Jenkins UI.
Deep down a job interface is xml on the Jenkins master instance, usually found at `${JENKINS_HOME}/jobs`.
We use a job interface to declare input parameters and to trigger the job.
Preferably, a job interface is created using the Jenkins [jobDSL plugin][jobdsl-plugin].
When a job is triggered it loads the pipeline definition.
{: .text-justify}

#### Pipeline Definition
A pipeline definition is a groovy script which is loaded by a job interface when a job is triggered.
Those groovy scripts are also known as pipeline-as-code - an approach also known from cloud CIs like Travis or CircleCI.
{: .text-justify}

#### Configuration Script
A configuration script is a system groovy script, which interacts with the Jenkins eco-system to configure Jenkins and its plugins.
{: .text-justify}

#### CasC
\[C\]onfiguration \[as\] [C]ode refers to the [Configuration-as-Code Plugin][casc-plugin].
Rather than writing configuration scripts, this plugin allows to define your configuration
in a simple .yaml syntax.
{: .text-justify}

#### JobDSL Script
A jobDSL script is a groovy script which programmatically describes job interfaces.
It is read by the Jenkins [jobDSL plugin][jobdsl-plugin] to create the job interfaces.
{: .text-justify}

#### Seeding
Seeding refers to creating all job interfaces from a single pipeline (the seeding job).
That pipeline executes the jobDSL scripts in order to create all job interfaces.
{: .text-justify}

### Layers and their Interaction

**Layers in jenkins-as-code:**
<img src="/content-images/jenkins-as-code-layers.png" alt="Layers in jenkins-as-code" style="display: block; margin-left: auto; margin-right: auto; width: 80%;">

**Interaction between the layers:**
<img src="/content-images/jenkins-as-code-layers-interaction.png" alt="Layer interaction in jenkins-as-code" style="display: block; margin-left: auto; margin-right: auto; width: 80%;">

## Jenkins Docker Image

Now that we have covered some basics, let us begin with the hands-on work and create a docker image for our Jenkins.
{: .text-justify}

### Directory Structure

We will use the following directory structure:
{: .text-justify}

```
docker/
|-- Dockerfile
|-- dsl
|   `-- ConfigurationAndSeedingPipelineDSL.groovy
|-- init.groovy.d
|   `-- init.groovy
`-- plugins.txt
```

The following sub-sections show the files in detail.
{: .text-justify}

### Dockerfile and Plugins

We want to build an image which automatically bootstraps our Jenkins with an initial job interface for configuration and seeding.
{: .text-justify}

**Dockerfile:**
{% gist fishi0x01/2b33eb533deae0a78ce23b108849bfdc Dockerfile %}

{% include tags/hint-start.html %}
**NOTE:** That Dockerfile also installs HashiCorp's Vault. While it is not needed in this part of the series we install it anyways for later use.
{: .text-justify}
{% include tags/hint-end.html %}

Also, we must ensure that some plugins are installed.
{: .text-justify}

**plugins.txt:**
{% gist fishi0x01/2b33eb533deae0a78ce23b108849bfdc plugins.txt %}

Most of those plugins are not necessary at this step of the series, but might come in handy later on. 
{: .text-justify}

{% include tags/hint-start.html %}
**NOTE:** Plugin versions are not pinned here as this is a demo. 
However, I recommend to pin the plugin versions inside the `plugins.txt` in order to have deterministic docker image builds. 
{: .text-justify}
{% include tags/hint-end.html %}

### Initial Pipeline Interface

The seed and configuration job interface is created through a jobDSL script.
{: .text-justify}

**ConfigurationAndSeedingPipelineDSL.groovy:**
{% gist fishi0x01/2b33eb533deae0a78ce23b108849bfdc ConfigurationAndSeedingPipelineDSL.groovy %}

### init.groovy.d for initial setup

`init.groovy.d` is a directory in the jenkins home directory, which contains configuration scripts.
Configuration scripts inside that directory are executed in alphabetical order at Jenkins boot time.
This is ideal for setting up seeding and configuration job interfaces.
{: .text-justify}

**init.groovy:**
{% gist fishi0x01/7c2d29afbaa0f16126eb4d4b35942f76 init.groovy %}

This script first adds a SSH private deploy key to Jenkins with access permissions to the shared library repository.
Further, the script creates a configuration and seed job from a jobDSL script.
That job will be used to pull the shared library from git and rollout its configuration and jobDSL definitions.
{: .text-justify}

{% include tags/hint-start.html %}
**NOTE:** The script assumes that the SSH key is already created and mounted into the docker container. The corresponding public key must be uploaded to GitHub as a deploy key for the shared library repository in order for Jenkins to pull it.
{: .text-justify}
{% include tags/hint-end.html %}

When you build this docker image and start the container, `init.groovy.d` will add your (mounted) SSH deploy key and create the configuration and seeding job interface.
When this interface is triggered, it will load the central shared library and run our pipeline defintions.
{: .text-justify}

## Shared Library Repository

Lets have a look now at how our shared jenkins library looks like.
{: .text-justify}

### Directory Structure

We will use the following directory structure for our shared library:
{: .text-justify}

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

The `vars` directory will contain our job pipeline (build/deploy).
Those pipelines will be called from a `Jenkinsfile` inside one of our projects, but we will focus on that in a later part of this series and can leave it empty.
Also the `resources/jobDSL` directory which is intended for job definitions will be left out for now.
We will come back to in a later part of this series.
For now we focus on the `resources/init` and `resources/config` directories.
`resources/init` holds initial configuration and seeding pipelines which leverage scripts in `resources/config` and `resources/jobDSL` to configure and seed jobs.
{: .text-justify}

In addition, we need a configuration and seeding pipeline script in the shared library repository.
{: .text-justify}

**ConfigurationAndSeedingPipeline.groovy:**
{% gist fishi0x01/2b33eb533deae0a78ce23b108849bfdc ConfigurationAndSeedingPipeline.groovy %}

The scripts loaded and executed in this job definition, e.g., `triggerConfigurationAsCodePlugin.groovy` or `timezone.groovy` are discussed in the [next part][next-part] of this jenkins-as-code series.
{: .text-justify}

## Summary

We now have a pipeline definition for configuration and seeding.
That pipeline defintion is triggered by an initial job interface for configuration and seeding.
The initial job interface is bootstrapped by our docker image (`init.groovy.d`).
{: .text-justify}

The [next part][next-part] of the jenkins-as-code series will focus on the configuration scripts, 
e.g., OAuth authentication, theming, slack and credentials.
{: .text-justify}

[next-part]: /weblog/2019/01/12/jenkins-as-code-part-2/
[travis]: https://travis-ci.com/
[circleci]: https://circleci.com/
[jobdsl-plugin]: https://github.com/jenkinsci/job-dsl-plugin
[pipeline-as-code]: https://jenkins.io/solutions/pipeline/
[shared-libraries]: https://jenkins.io/doc/book/pipeline/shared-libraries/
[jenkins-as-code-github-repo]: https://github.com/devtail/jenkins-as-code
[casc-plugin]: https://plugins.jenkins.io/configuration-as-code
