### How to Use?

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
