# this is a bootstrap formula, we init salt file_roots and that's it!
# default to using the git repo and deb package installers
base:
  '*':
    - salt.file_roots.git
    - salt.file_roots.deb
