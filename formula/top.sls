# this is a bootstrap formula, we init salt file_roots and that's it!
# default to using the git repo and deb package installers
{%- set deb = salt['pillar.get']('file_roots_deb', False) %}
{%- set git = salt['pillar.get']('file_roots_git', False) %}
{%- set one = salt['pillar.get']('file_roots_single', False) %}
      
base:
  '*':
    {% if deb %}- salt.file_roots.deb{% endif %}
    {% if git %}- salt.file_roots.git{% endif %}
    {% if one %}- salt.file_roots.single{% endif %}

