---
layout: post
title: "My Consul Service ID hunt"
date: 2017-09-09 09:21:22 +0000
modified: 2017-11-28 17:28:34 +0000 
comments: true
disqus_id: 14
permalink: weblog/2017/09/09/consul-service-id-hunt/
categories: consul
---

This is a rather short post about a recent annoying issue I stumbled across. 
As the title suggests I wanted to retrieve the ID of a service from a consul node. Easy as this may sound, the [documentation](https://www.consul.io/api/agent/service.html#service_id) is not very clear about what the service ID really looks like or how I can find it. 
(FYI: At the time of writing I was running consul `0.8.1` and vault `0.7.0`)
{: .text-justify}
<!--more-->

What actually happened: I accidentally registered my [vault](https://www.vaultproject.io/) server directly with the consul server nodes, but ideally it should be connected to a local consul agent instead. 
After realizing my mistake, I properly hooked up the vault node with its local consul agent. 
Besides being registered now on the correct node, the vault service was still also registered on the consul server node and marked as failing there ..
On the first view this looks like a simple problem to solve .. 
Consul offers a [HTTP API](https://www.consul.io/api/index.html) which you can also use to [deregister services](https://www.consul.io/api/agent/service.html#deregister-service) on nodes manually. 
Straight forward - or so it seems..
{: .text-justify}

According to the documentation and assuming I can reach my consul node via localhost I just need to run: 
{: .text-justify}

```
curl -v -X PUT http://localhost:8500/v1/agent/service/deregister/:service_id
```

But wait - what's my `:service_id`??? I figured, that my vault's `:service_id` might as well be the name of the service itself: `vault`. 
It didn't work:
{: .text-justify}

```
$ curl -sX PUT http://localhost:8500/v1/agent/service/deregister/vault
Unknown service "vault"
```
 
Seems `vault` is really just a service name and not a proper service id. 
My failing vault service is still showing up inside the consul catalog .. 
{: .text-justify}

After some reading, I query the service [catalog API](https://www.consul.io/api/catalog.html#list-services) to get some more meta information:
{: .text-justify}

```
curl -sX PUT http://localhost:8500/v1/catalog/service/:service_name
```

The result of this query looks like that:
{: .text-justify}

```
$ curl -sX PUT http://localhost:8500/v1/catalog/service/vault | jq
[
  {
    "ID": "<uuid>",
    "Node": "kernel-terra-vault-0",
    "Address": "10.5.1.200",
    "TaggedAddresses": {
      "lan": "10.5.1.200",
      "wan": "10.5.1.200"
    },
    "NodeMeta": {},
    "ServiceID": "vault:10.5.1.200:8200",
    "ServiceName": "vault",
    "ServiceTags": [
      "active"
    ],
    "ServiceAddress": "10.5.1.200",
    "ServicePort": 8200,
    "ServiceEnableTagOverride": false,
    "CreateIndex": <some index>,
    "ModifyIndex": <some index>
  },
  {
    "ID": "<uuid>",
    "Node": "kernel-terra-vault-1",
    "Address": "10.5.1.201",
    "TaggedAddresses": {
      "lan": "10.5.1.201",
      "wan": "10.5.1.201"
    },
    "NodeMeta": {},
    "ServiceID": "vault:10.5.1.201:8200",
    "ServiceName": "vault",
    "ServiceTags": [
      "standby"
    ],
    "ServiceAddress": "10.5.1.201",
    "ServicePort": 8200,
    "ServiceEnableTagOverride": false,
    "CreateIndex": <some index>,
    "ModifyIndex": <some index>
  },
  {
    "ID": "<uuid>",
    "Node": "kernel-terra-vault-1",
    "Address": "10.5.1.100",
    "TaggedAddresses": {
      "lan": "10.5.1.100",
      "wan": "10.5.1.100"
    },
    "NodeMeta": {},
    "ServiceID": "vault:10.5.1.100:8200",
    "ServiceName": "vault",
    "ServiceTags": [
      "standby"
    ],
    "ServiceAddress": "10.5.1.100",
    "ServicePort": 8200,
    "ServiceEnableTagOverride": false,
    "CreateIndex": <some index>,
    "ModifyIndex": <some index>
  }
]
```
Very interesting! It looks like `:service_id` is actually a combination of the service name, the node's ip and the service port! 
This means that for one service across the whole cluster every offering node has a unique `:service_id` for that service. 
{: .text-justify}

In my case, `10.5.1.100` is the consul server node on which I want to deregister vault. I run:
{: .text-justify}

```
$ curl -sX PUT http://localhost:8500/v1/agent/service/deregister/vault:10.5.1.100:8200
```

It worked! The faulty vault service got successfully deregistered on server node `10.5.1.100`.
{: .text-justify}

Lesson learned: `:service_id != :service_name`
{: .text-justify}

{% include tags/hint-start.html %}
Note: You should do the mentioned queries against a consul agent with the necessary privileges in case you activated the [consul ACL](https://www.consul.io/docs/guides/acl.html). In any case it should work if you do the query against the agent on which the service is running that you want to deregister, as usually that node must have permissions to register/deregister the service in the first place.
{: .text-justify}
{% include tags/hint-end.html %}

