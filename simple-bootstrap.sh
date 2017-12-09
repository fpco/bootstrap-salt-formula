#!/bin/sh

##########
# Step 1: Install Saltstack and git
wget -O bootstrap-salt.sh https://bootstrap.saltstack.com
sh bootstrap-salt.sh
# disable the service until configured
service salt-minion stop
# the bootstrap formula might need git installed..
apt-get install -y git

###########
# Step 2: install the bootstrap formula
wget -O - https://raw.githubusercontent.com/fpco/bootstrap-salt-formula/master/install.sh | sh

###########
# Step 3: configure the bootstrap formula
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

###########
# Step 4: bootstrap salt formula!
salt-call --local                                           \
          --file-root   /srv/bootstrap-salt-formula/formula \
          --pillar-root /srv/bootstrap-salt-formula/pillar  \
          --config-dir  /srv/bootstrap-salt-formula/conf    \
          state.highstate
