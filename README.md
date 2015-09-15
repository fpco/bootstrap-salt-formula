### How to Use?

```
# get the source!
git clone https://github.com/fpco/bootstrap-salt-formula /srv/salt/bootstrap-formula

# consul bootstrap.EXAMPLE for more inspiration..
vim /srv/salt/bootstrap-formula/pillar/bootstrap.sls

# run the formula bootstrap, independent of the rest of your formula
salt-call --local                                           \
          --file-root   /srv/salt/bootstrap-formula/formula \
          --pillar-root /srv/salt/bootstrap-formula/pillar  \
          --config-dir  /srv/salt/bootstrap-formula/conf    \
          state.sls salt.file_roots
```
