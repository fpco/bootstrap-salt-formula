# formula to seed Salt's file_roots with a bunch of git repos
# assume there is other formula that will take care of configuring
# SaltStack master/minion with these file_roots, just focus on git checkout
#
# this formula supports _multiple_ git repos > /srv/salt/


# the list of packages to install, expected as a dict with {name: {url/rev}} for
# each repo to use as file_roots
{%- set install_list = salt['pillar.get']('file_roots_git:install', {}) %}
# the list of packages to remove/uninstall, expected as a list of package names
{%- set absent_list = salt['pillar.get']('file_roots_git:absent', []) %}
# the list of packages to set as active (in file_roots), expected as a list of package names
{%- set active_list = salt['pillar.get']('file_roots_git:active', install_list) %}

# user to run the git checkout as
{%- set user = salt['pillar.get']('file_roots_git:user', 'root') %}
# SSH key for git checkout
{%- set ssh_key_path = salt['pillar.get']('file_roots_git:ssh_key_path', '/root/.ssh/id_rsa') %}
# where to checkout / install all git-based, packaged formula
{%- set roots_root = salt['pillar.get']('file_roots_git:roots_root', '/srv/salt-git') %}


include:
  - git


# SSH key to use for git checkout
roots-ssh-key:
  file.exists:
    - name: {{ ssh_key_path }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 600

# root path for all file_roots checked out
roots-root-git:
  file.directory:
    - name: {{ roots_root }}
    - user: {{ user }}
    - mode: 750
    - makedirs: True


# generate the `git.latest` states for the file_roots to checkout
{%- for repo, conf in install_list.items() %}
{%- set url = conf['url'] %}
{%- set rev = conf['rev'] %}

roots-git-{{ repo }}:
  git.latest:
    - name: {{ url }}
    - rev: {{ rev }}
    - target: {{ roots_root }}/{{ repo }}
    - user: {{ user }}
    - force: True
    - force_checkout: True
    - identity: {{ ssh_key_path }}
    - require:
        - file: roots-ssh-key
        - file: roots-root-git
        - pkg: git

{%- endfor %}


# iterate over creating master.d and minion.d in /etc/salt/
{%- for m in 'master', 'minion' %}
# file_roots config will go in here
{%- set conf_root = '/etc/salt/' + m + '.d' %}
{%- set conf_file = conf_root + '/file_roots_git.conf' %}

# create a conf for file_roots, as seen by the {{ m }}
salt-formula-git-pkg-{{ m }}-config:
  file.managed:
    - name: {{ conf_file }}
    - user: root
    - group: root
    - mode: 640
    # incase the conf path does not exist
    - makedirs: True
    - contents: |
        # skip if the list is empty
        {%- if active_list %}
        file_roots:
          base:{% for pkg in active_list %}
            - {{ roots_root }}/{{ pkg }}
            {%- endfor %}
        {%- endif %}

{%- endfor %}


# packages to uninstall..
{%- for pkg in absent_list %}
  file.absent:
    - name: {{ roots_root }}/{{ pkg }}'
{%- endfor %}
