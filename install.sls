# user to run the git checkout as
{%- set user = salt['pillar.get']('file_roots_bootstrap:user', 'root') %}
# SSH key for git checkout
{%- set ssh_key_path = salt['pillar.get']('file_roots_bootstrap:ssh_key_path', '/root/.ssh/id_rsa') %}
# where to checkout to, root path
{%- set roots_root = salt['pillar.get']('file_roots_bootstrap:roots_root', '/srv/bootstrap-salt-formula') %}
# name/url/rev for each repo to use as file_roots
{%- set url = salt['pillar.get']('file_roots_bootstrap:url', 'https://github.com/fpco/bootstrap-salt-formula') %}
{%- set rev = salt['pillar.get']('file_roots_bootstrap:rev', 'master') %}
{%- set script_path = salt['pillar.get']('file_roots_bootstrap:script_path', '/usr/local/sbin/bootstrap-salt-formula') %}
{%- set log_path = salt['pillar.get']('file_roots_bootstrap:log_path', '/var/log/bootstrap-salt-formula.log') %}
{%- set cron_minute = salt['pillar.get']('file_roots_bootstrap:cron_minute', '*/5') %}
{%- set cron_hour = salt['pillar.get']('file_roots_bootstrap:hour', '*') %}

{%- if 'git@' in url %}
# SSH key to use for git checkout
roots-ssh-key:
  file.exists:
    - name: {{ ssh_key_path }}
{%- endif %}

# root path for file_roots bootstrap checked out
roots-root:
  file.directory:
    - name: {{ roots_root }}
    - user: {{ user }}
    - mode: 750
    - makedirs: True


# use git to install the file_roots bootstrap formula
install-salt-formula-bootstrap-formula:
  git.latest:
    - name: {{ url }}
    - rev: {{ rev }}
    - target: {{ roots_root }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - force_checkout: True
    - require:
        - file: roots-root
    {%- if 'git@' in url %}
        - file: roots-ssh-key
    - identity: {{ ssh_key_path }}
    {%- endif %}
  file.managed:
    - name: {{ script_path }}
    - user: root
    - group: root
    - mode: 750
    - require:
        - git: install-salt-formula-bootstrap-formula
    - contents: |
        #!/bin/sh
        salt-call --local                                 \
                  --config-dir {{ roots_root }}/conf      \
                  --pillar-root {{ roots_root }}/pillar   \
                  --file-root {{roots_root }}/formula     \
                  state.highstate
  cmd.run:
    - name: 'echo "use {{ script_path }} to run the file_roots bootstrap formula"'
    - require:
        - file: install-salt-formula-bootstrap-formula
  cron.present:
    - name: '{{ script_path }} > {{ log_path }} 2>&1'
    - user: root
    - minute: '{{ cron_minute }}'
    - hour: '{{ cron_hour }}'
    - comment: periodically run bootstrap to refresh
    - identifier: bootstrap-salt-formula
    - require:
        - file: install-salt-formula-bootstrap-formula
