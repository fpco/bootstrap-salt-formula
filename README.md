# Bootstrap Salt Formula

Opinionated formula to bootstrap other formula for Saltstack. It is very awesome,
but use it at your own risk.


## What is this?

* Formula for the Saltstack configuration management system.
* Formula that installs other formula, and sets up Saltstack to use that formula
* Independent configuration and formula file_roots for the bootstrap (de-coupled
  from the host's CM configuration, if you break one, the other is functional).
* Something easier than git_file_roots and similar capabilities built into Salt


## What does it do?

`bootstrap-salt-formula` runs in one of several modes with the following behavior:

* setup file_roots with a single git repo
* setup file_roots with multiple git repos
* fetch and install a `.deb` package from an HTTP URL, then setup file_roots with
  that package.


## How to Use?

You'll need Saltstack and git to get going, that's it.


### Automated Install

For provisioning linux hosts or building images with Packer, here is a method for
automated systems. Note that the first step is optional and only included for
demonstration:

```
#!/bin/sh

##########
## Update this section to fit your linux distro of choice
# Step 1: Install Saltstack and git
# this will give us the latest Saltstack
add-apt-repository -y ppa:saltstack/salt
# ensure we get zmq v4
add-apt-repository -y ppa:chris-lea/zeromq
# ensure PPAs are active and install the salt minion!
apt-get update
apt-get install -y salt-minion
# disable the service until configured
service salt-minion stop

# the bootstrap formula might need git installed..
apt-get install -y git
###########


# Step 2: accept github's SSH key for strict host key verification, git.latest
# will fail unless this has been done either manually or with salt like this
salt-call --local                              \
          state.single ssh_known_hosts.present \
          name=github.com enc=ssh-rsa          \
          fingerprint=16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48


# Step 3: clone our salt formula to bootstrap salt formula
salt-call --local                                             \
          state.single git.latest                             \
          rev=master                                          \
          name=git@github.com:fpco/bootstrap-salt-formula.git \
          target=/srv/bootstrap-salt-formula


# Step 4: configure the bootstrap formula
# edit this to enter your bootstrap pillar here, or upload during provisioning
cat <<END_PILLAR > /srv/bootstrap-salt-formula/pillar/bootstrap.sls
# for the `salt.file_roots.single` formula
file_roots_single:
  #user: root
  #ssh_key_path: /root/.ssh/id_rsa
  roots_root: /srv/salt
  url: git@github.com:fpco/fpco-salt-formula.git
  rev: master
END_PILLAR


# Step 5: bootstrap salt formula!
salt-call --local                                           \
          --file-root   /srv/bootstrap-salt-formula/formula \
          --pillar-root /srv/bootstrap-salt-formula/pillar  \
          --config-dir  /srv/bootstrap-salt-formula/conf    \
          state.highstate
```

This does the following:

* install Saltstack and git (customize that for your linux system of choice)
* use salt to accept github's SSH pubkey, based on the published fingerprint
* use salt to clone the bootstrap-salt-formula git repo to `/srv/bootstrap-salt-formula`
* write out pillar to instruct how you want to bootstrap salt formula on the host
* use the bootstrap formula to bootstrap formula for salt (`state.highstate`
  will determine which formula to apply based on the pillar key(s) you have
  provided).

See details below on customizing the pillar to configure the bootstrap formula.


### Manual Install

Assuming salt and git are installed, here is a manual setup:

```
# install
git clone git@github.com/fpco/bootstrap-salt-formula /srv/bootstrap-salt-formula

# update /srv/bootstrap-salt-formula/pillar/bootstrap.sls to meet your needs

# run
salt-call --local                                           \
          --file-root   /srv/bootstrap-salt-formula/formula \
          --pillar-root /srv/bootstrap-salt-formula/pillar  \
          --config-dir  /srv/bootstrap-salt-formula/conf    \
          state.highstate
```


## Bootstrapping Modes

The formula is setup to support different bootstrapping scenarios. These modes of
operation have been developed out of need, and have held their ground under fire
in production.. but it is not exhaustive, so feel free to recommend new methods
that would improve this collection.

Run only one mode at a time, and manually remove the offending Salt configuration
file(s) from `/etc/salt/{master.d,minion.d}/file_roots_*.conf` if there is a
conflict between multiple configuration states you have put in place.


### Single git repo

For the times where you have a single git repository that contains all of your
salt formula:

```
file_roots_single:
  user: root
  ssh_key_path: /root/.ssh/id_rsa
  roots_root: /srv/salt
  url: git@github.com:saltstack-formulas/salt-formula.git
  rev: develop
```

Note that the `user`, `ssh_key_path`, and `roots_root` keys are optional, with
the defaults shown here.


### Multiple git repos

More often than not, we actually source formula from multiple repositories, so
we need something a little more robust:

```
file_roots_git:
  # run the git checkout as this user
  user: root
  # SSH key for git checkouts
  ssh_key_path: /root/.ssh/id_rsa
  # file_roots source repos
  install:
    openssh-formula:
      url: https://github.com/saltstack-formulas/openssh-formula
      rev: '1b74efd'
    fail2ban-formula:
      url: https://github.com/saltstack-formulas/fail2ban-formula
      rev: 'master'
    fpco-salt-formula:
      url: git@github.com:fpco/fpco-salt-formula.git
      rev: 'develop'
  # update this list to choose the repos to enable, not listed == inactive
  #active:
  #  - salt-formula
```


### Installable .deb Package

An installable Debian package (`.deb`) provides for a few interesting advantages
over sourcing formula from git repositories:

* Clear build process, more easily and reliably reproducible in the future.
* A bit more robust in archival - a git repository's history may change, but the
  `.deb` will be the same.
* Better performant, pre-built and hosted `.deb` formula is minimal in file
  transfer, and faster to update, especially for distributed systems with many nodes.


```
file_roots_deb:
  install:
    salt-formula:
      url: http://ubuntu.example.com/salt-formula-v2015-09-15.deb
      checksum: FFAADD
  absent:
    - old-formula-v2015-07-20
  active:
    - salt-formula-v2015-09-15
```

The `file_roots_deb` formula will download the `.deb`, verify the checksum,
install it with the `dpkg` utility, and uninstall and unregister any formula
packages included in the `absent` list.


## Integration with Consul

By combining this formula to bootstrap Saltstack formula with other tools, we can
easily establish a powerful method for managing the CM formula across the
diversity of your deployments.

For example, we can combine this formula for Saltstack with consul to distribute
the bootstrap pillar, and consul-template to write out that pillar and run the
bootstrap when the bootstrap key changes.

To do that, one would configure consul-template with:

```
template {
  source = "/srv/consul-templates/bootstrap_salt_formula.tpl"
    destination = "/srv/bootstrap-salt-formula/pillar/bootstrap.sls"
      command = "salt-call  --local  --file-root /srv/bootstrap-salt-formula/formula  --pillar-root /srv/bootstrap-salt-formula/pillar  --config-dir /srv/bootstrap-salt-formula/conf  state.highstate"
      }
```

With your cluster connected via consul, and consul-template running on all nodes,
updating the pillar in the `bootstrap_salt_formula` key in consul would trigger
all nodes to apply the bootstrap formula with your updated pillar.

That update might look like:

```
consulkv put bootstrap_salt_formula < /srv/bootstrap-salt-formula/pillar/bootstrap.sls
```

Note that, one could also remove `consul-template` from this picture, leaving
only Saltstack and Consul. In this configuration, one would need to configure
Consul with a watch on the formula bootstrap key and with a handler that applies
the bootstrap formula when that key changes. This would require configuring Salt
with Consul as an external pillar source. While using Consul as ext_pillar is
highly recommended, it is best to ensure the formula bootstrap methodology is
deployed in such a way that it is separate from your other Salt configuration.
Eg, a system to maintain the CM formula should run as an out-of-band service,
de-coupled from the primary CM system. This greatly simplifies fixing the CM
system when it is broken, and provides robustness in the face of chaos in the
cloud.
