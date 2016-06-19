---
layout: post
title:  "Testing ansible playbooks with ansible-vault encrypted data using Travis CI"
date:   2016-04-02 16:03:23 +0000
modified: 2015-05-26 09:04:33 +0000 
comments: true
permalink: weblog/2016/04/02/testing-ansible-ansible-vault-travis-ci
redirect_from:
  - /weblog/C/
categories: ansible ci
---

In this post I want to talk about using [ansible-vault][ansible-vault] to encrypt secret variables and templates in your ansible roles. 
Further, I want to have a look at how to test those playbooks and encrypted files using [Travis CI][travis]. 

The combination of ansible-vault and Travis CI seems a little odd on first sight and I must admit I've had trouble finding a proper way of handling private data in a public repository with an external and also public CI environment. 
Here is some little background information why I still chose such an approach:<!--more-->
My use case is an [open source project][himate] which uses ansible provisioning for its infrastructure. 
One sweet thing about ansible is that it is highly supported by tools such as [Packer][packer] and [Vagrant][vagrant] ([HashiCorp][hashicorp] in general does some really awesome stuff - I am also already curious to play around with [Otto][otto] and [Vault][vault] (not to be confused with ansible-vault)). 
I use Vagrant locally to develop my ansible roles and Packer can be used to create images (also [docker][docker] containers are possible) with these roles/playbooks which basically enables me to port my ansible described architecture to any kind of machine image. 
I find it tempting to also share infrastructure code, such as ansible scripts publicly, without risking security issues, but of course parts of the infrastructure such as keys, passwords etc. have to be kept secret. 
Further, when developing open source I can use services such as Travis CI to test my playbooks and roles for free, so I could test the whole setup instead of just single role rollouts. 
In the end of this post I will talk a little more about some security concerns. 
I think keeping up such an open approach in a secure way requires more maintenance on my side, but it is also an interesting challenge!

## Ansible - A simple example playbook ##

Lets first create a simple ssh role and playbook. 
In the next sections we will then step by step encrypt sensitive parts of that role. 
First, we create a template for the `sshd_config` file.

**roles/ssh/templates/sshd_config.j2**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-templates-sshd_config.j2 %}

This `sshd_config` handles access permissions based on the user groups. 
The group list `all_groups`, which contains all groups with ssh permissions must be visible for this template to render. 
Next, we define the task for the role. 
Basically all we need is to place the `sshd_config` file and restart the ssh daemon. 

**roles/ssh/tasks/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-tasks-main.yml %}

Now we need to define our default variables. 

**roles/ssh/defaults/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-defaults-main.yml %}

Please note, that the `sshd_groups` list could also be defined in a users/groups role, but to keep it simple we just define it for now as a defaults variable in our ssh role. 
We also need a service handler to restart our service. 

**roles/ssh/handlers/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-handlers-main.yml %}

Next, we need a playbook which uses our role.

**app.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 app.yml %}

This playbook rolls out the ssh role on all hosts in our inventory with the `app` tag. 
The `no_log` is set to avoid the logging of secret data in Travis later. 
Of course, while actively working on a playbook/role it might be easier for debugging to turn the logging on again by setting `no_log: no`, so inside the Travis build we just have to hand over an extra argument to disable the logging `--extra-vars='{\"disable_log\": \"yes\"}'`. 
Finally, we need an inventory file for development.

**inventories/dev**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 inventories-dev %}

Note, that the `app` host needs to be resolvable in order for this to work. 
You could add it to your `/etc/hosts`. 

We could now run our playbook via:

{% shell %}
ansible-playbook -i inventories/dev app.yml
{% endshell %}

We now have a simple and fully functional playbook. 
In the next sections I want to encrypt the secrets in our playbook and run tests via Travis CI.

## Encrypting secrets with ansible-vault ##

Now we discuss how we can encrypt secrets that should not be shared with everyone inside your company. 
First, we will have a look at how to encrypt and use secret variables. Second, we will look at secret config files / templates. 

### Secret Variables ###

In Ansible we can use a feature called [ansible-vault][ansible-vault] in order to encrypt our files which contain secrets. 
Simply use `ansible-vault encrypt <file>` in order to encrypt an existing file. 
You can also edit encrypted files (without decrypting them first on the disk) with `ansible-vault edit <file>` or create a new encrypted file via `ansible-vault create <file>`. 
Please consult the [documentation][ansible-vault] for more commands of `ansible-vault`. 

By storing the vault password in a file we can use our playbooks without decrypting the encrypted files directly on the disk. 
As an example we could use the following command to rollout a playbook with vault encrypted files: 

{% shell %}
ansible-playbook -i inventories/travis my-playbook.yml --vault-password-file vault_pass_file
{% endshell %}

Ansible will then decrypt the files in memory and rollout the playbook. 

{% hint %}
Remember to add the `vault_pass_file` to your `.gitignore`, so you do not add the password to your repository by accident. 
{% endhint %}

For our playbook example from the previous section, we could encrypt our default variables, to keep our port and group access settings a secret. 
First, we generate a complex vault password and store it in `vault_pass_file`. 
Then, we run:

{% shell %}
ANSIBLE_VAULT_PASSWORD_FILE=vault_pass_file ansible-vault encrypt roles/ssh/defaults/main.yml
{% endshell %}

We could then rollout the playbook via:

{% shell %}
ansible-playbook -i inventories/dev app.yml --vault-password-file vault_pass_file
{% endshell %}

### Secret Templates ###

In the first place `ansible-vault` is designed to encrypt files containing secret variables, such as files in the `group_vars` or `host_vars` directories, but theoretically we can also use it to encrypt templates. 
If I want to keep config files such as `sshd_config` or nginx config files secret, then I can use ansible-vault to encrypt their templates. 
The problem with encrypting templates is that ansible assumes that templates or files which are copied to the server are already unencrypted. 
Thus, we cannot use on the fly in memory decryption by simply specifying the `--vault-password-file` flag, but we need to decrypt the templates/files on disk before we rollout playbooks. 
There is a [discussion][ansible-discuss] on github about enabling this feature and currently there is [some work][ansible-pull] done on the file lookup feature to allow encrypted templates/files.

Lets rename our `sshd_config.j2` template to `sshd_config.j2.enc` and encrypt it by simply running:

{% shell %}
ANSIBLE_VAULT_PASSWORD_FILE=vault_pass_file ansible-vault encrypt roles/ssh/templates/sshd_config.j2.enc
{% endshell %}

We now need to make a small adjustment to our ssh role's `main.yml`, so it first locally decrypts the template and after the rollout removes the decrypted template again.

**Modified roles/ssh/tasks/main.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 roles-ssh-tasks-main-decrypt.yml %}

{% hint %}
Note, that I set `changed_when: False` for decryption and removal, since without it each run would result in changes, which would make idempotency tests very difficult. 
Also, `local_action` has problems to source the python virtualenv inside Travis, which is why I handle the decryption inside Travis with a separate script. 
This does not affect non-Travis rollouts.
{% endhint %}

In case we are not dealing with templates, but with static encrypted files instead, we could use the Ansible `lookup` feature together with the `content` setting of the `copy` module:

```
{% raw %}
content={{ lookup('pipe', 'ansible-vault --vault-password-file vault_pass_file view secret.file') }}
{% endraw %}
```

## Travis CI - Testing my playbooks ##

We now want to test our playbooks with [Travis CI][travis]. 

In general this is very easy to setup, but when using `ansible-vault` encrypted files we need to do some extra steps in order for Travis to know the vault password. 

### Simple tests without encryption ###

First, we create simple ansible tests assuming our files are all unencrypted. 
We need a Travis CI account (for open source projects you can use Travis for free!). 
Travis uses a file called `.travis.yml` in the top directory of your project to read the test configurations. 
You can use this file to setup and run your tests inside the Travis infrastructure. 

**.travis.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 decrypted.travis.yml %}

This configuration initially installs ansible inside the Travis VM. 
It also sets `app` in `/etc/hosts` to point to localhost. 
Next, we run 3 tests in the script section. 
The first test is a simple syntax check to catch the most obvious errors. 
Next, we rollout the playbook against the local VM. 
Finally, we make an idempotence test by rolling out the same playbook against localhost again. 
In order to succeed this test, there should not be any changes. 

{% hint %}
Currently we only have one playbook to test, but we can simply test multiple playbooks in parallel by adding them to the `env.matrix` section. 
For instance if we had a playbook `db.yml`, we could also test it in parallel by simply adding it to the test matrix:

<pre>
env:
  global:
    - ANSIBLE_VERSION=2.0.1.0
  matrix:
    - PLAYBOOK=app.yml
    - PLAYBOOK=db.yml
</pre>
{% endhint %}

### Tests with encrypted files ###

We also want to test our playbooks when they reference encrypted variables and in order for this to work we need to give Travis knowledge about how to decrypt them. 
For each project Travis generates a public / private keypair, which can be used to share secrets. 
We can then use the [Travis CLI][travis-cli] to encrypt values which can later be decrypted by the private key inside the Travis infrastructure for your project. 
Here is the official documentation about [file encryption in Travis][travis-encrypt].

In our case one way to approach this problem is by encrypting our `vault_pass_file` to `vault_pass_file.enc` with a complex password via OpenSSL. 

{% shell %}
openssl aes-256-cbc -k "&lt;my-very-strong-password&gt;" -in vault_pass_file -out vault_pass_file.enc
{% endshell %}

We could then add the `vault_pass_file.enc` to our repository and use Travis CLI to give Travis knowledge about the password to be able to decrypt the `vault_pass_file.enc`. 
To share the password with travis, we first need to authenticate with Travis CLI.

{% shell %}
travis login
{% endshell %}

Next, we need to define an encrypted environment variable (in our case we name it `vault_file_pass`) which stores the password.

{% shell %}
travis encrypt vault_file_pass=&lt;my-very-strong-password&gt; --add
{% endshell %}

The `--add` flag adds the encrypted data to your `env` map inside the `.travis.yml` file. 

Finally, we need to tell Travis to decrypt `vault_pass_file.enc` in the `before_install` step and decrypt the template files for the tests. 
Your `.travis.yml` file should now look something like that.

**.travis.yml**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 var_encrypted.travis.yml %}

{% hint %}
Note, that after running the tests I run `.travis/sensitive_data.sh clean` and `shred vault_pass_file` in the `after_script` section to remove the decrypted flles and the cleartext vault password from the Travis VM. 
{% endhint %}

As mentioned above, I had trouble using `local_action` within the Travis environment, since it does not properly source the python virtual environment and thus cannot find the `ansible-vault` command. 
I am still investigating this, but in the meanwhile as a workaround I wrote a script that Travis can use to decrypt the templates before running (and also clean them up after the build is done).

Here is an example of what the `.travis/sensitive_data.sh` could look like:

**.travis/sensitive_data.sh**

{% gist fishi0x01/4d613f4fb0034b7197a92cd36bd34801 .travis_sensitive_data.sh %}

### Some security concerns ###

While testing with Travis CI is quite comfortable, an obvious issue is that Travis needs to be able to decrypt your secrets. 
Also, you create VMs/Containers inside the Travis infrastructure which contain your decrypted setups. 
This means, that if Travis gets compromised so are your secrets. 
To work around that issue you should consider using fake data in your tests for the most important secrets such as private keys (go snakeoil!!!). 
That way the provisioned VMs/Containers do not hold any critical security relevant keys. 
What makes this approach difficult is that ansible-vault only allows one vault password for all the files. 
Thus, we should at least store real private keys in a different directory which is not part of the repository or encrypt them using another password (which means we would need to decrypt them on disk before using them again, since ansible will use the same provided password to decrypt all the files). 
Your templates and less important secret variables are still visible to Travis, but at least your private keys and other very important secrets are kept private. 
Another issue is if your tests require valid SSL certificates in order to run (think end-to-end testing). 
In that case you might need to apply some workarounds in your test scripts to allow insecure certificates. 
Of course this adds more maintenance work on your part, but the privacy of your private keys should be worth the effort. 


[ansible-vault]: http://docs.ansible.com/ansible/playbooks_vault.html
[travis]: https://travis-ci.org/
[himate]: https://github.com/himate
[packer]: https://www.packer.io/
[vagrant]: https://www.vagrantup.com/
[hashicorp]: https://www.hashicorp.com/
[otto]: https://www.ottoproject.io/
[vault]: https://www.vaultproject.io/
[docker]: https://www.docker.com/
[ansible-discuss]: https://github.com/ansible/ansible/issues/6596
[ansible-pull]: https://github.com/ansible/ansible/pull/8110
[travis-cli]: https://github.com/travis-ci/travis.rb
[travis-encrypt]: https://docs.travis-ci.com/user/encrypting-files/
