# formula to seed Salt's file_roots with a _single_ git repo
# this may fail if /srv/salt is already populated with other formula
{%- set user = salt['pillar.get']('file_roots_single:user', 'root') %}
{%- set roots_root = salt['pillar.get']('file_roots_single:roots_root', '/srv/salt') %}
{%- set ssh_key_path = salt['pillar.get']('file_roots_single:ssh_key_path', '/root/.ssh/id_rsa') %}
{%- set url = salt['pillar.get']('file_roots_single:url') %}
{%- set rev = salt['pillar.get']('file_roots_single:rev') %}

include:
  - git


salt-roots:
  file.exists:
    - name: {{ ssh_key_path }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 600
  git.latest:
    - name: {{ url }}
    - rev: {{ rev }}
    - target: {{ roots_root }}
    - user: {{ user }}
    - force_reset: True
    - force_fetch: True
    - force_checkout: True
    - identity: {{ ssh_key_path }}
    - require:
        - file: salt-roots
        - pkg: git


# iterate over creating master.d and minion.d in /etc/salt/
{%- for m in 'master', 'minion' %}
# file_roots config will go in here
{%- set conf_root = '/etc/salt/' + m + '.d' %}
{%- set conf_file = conf_root + '/file_roots_single.conf' %}

# create a conf for file_roots, as seen by the {{ m }}
salt-formula-single-pkg-{{ m }}-config:
  file.managed:
    - name: {{ conf_file }}
    - user: root
    - group: root
    - mode: 640
    # incase the conf path does not exist
    - makedirs: True
    - contents: |
        file_roots:
          base:
            - {{ roots_root }}
{%- endfor %}


