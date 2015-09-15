### How to Use?

```
git clone https://github.com/fpco/bootstrap-salt-formula /srv/salt-bootstrap-formula

salt-call --local                                           \
          --file-root   /srv/salt-bootstrap-formula/formula \
          --pillar-root /srv/salt-bootstrap-formula/pillar  \
          --config-dir  /srv/salt-bootstrap-formula/conf    \
          state.sls salt.file_roots
```
