# install / manage salt formula via one or more debian packages
#
# Pillar to config the formula is pulled from the `file_roots_deb` key.
# For each package listed in the `install` key, this formula will download
# the .deb and install it with `dpkg --install`. Similarly, for those pkg
# in the `absent` key, `dpkg --remove` will be used to remove the pkg. For
# those pkg in `active`, they will be listed in the `file_roots` key
# created in the minion/master configs.
#

# system-wide location for salt/pillar/etc
{%- set salt_root = '/srv' %}
# where to install all debian-based, packaged formula
{%- set pkg_root = salt_root + '/salt-deb' %}
# the list of packages to install, expected as a dict of {'name': {'url': '', 'checksum': ''} }
{%- set install_list = salt['pillar.get']('file_roots_deb:install', {}) %}
# the list of packages to remove/uninstall, expected as a list of package names
{%- set absent_list = salt['pillar.get']('file_roots_deb:absent', []) %}
# the list of packages to set as active (in file_roots), expected as a list of package names
{%- set active_list = salt['pillar.get']('file_roots_deb:active', install_list) %}


# create the directory all packaged formula will be installed to
salt-formula-deb-pkg-root-path:
  file.directory:
    - name: {{ pkg_root }}
    - user: root
    - group: root
    - mode: 750
    - makedirs: True


# iterate over creating master.d and minion.d in /etc/salt/
{%- for m in 'master', 'minion' %}
# file_roots config will go in here
{%- set conf_root = '/etc/salt/' + m + '.d' %}
{%- set conf_file = conf_root + '/file_roots_deb.conf' %}

# create a conf for file_roots, as seen by the {{ m }}
salt-formula-deb-pkg-{{ m }}-config:
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
            - {{ pkg_root }}/{{ pkg }}
            {%- endfor %}
        {%- endif %}

{%- endfor %}


# packages to install..
{%- for pkg, conf in install_list.items() %}
salt-formula-deb-install-{{ pkg }}:
  file.managed:
    - name: {{ pkg_root }}/{{ pkg }}.deb
    - source: {{ conf['url'] }}
    - source_hash: sha512={{ conf['checksum'] }}
    - user: root
    - group: root
    - mode: 640
    - require:
        - file: salt-formula-deb-pkg-root-path
  cmd.run:
    - name: 'dpkg --install {{ pkg_root }}/{{ pkg }}.deb'
    - require:
        - file: salt-formula-deb-install-{{ pkg }}
{%- endfor %}


# packages to uninstall..
{%- for pkg in absent_list %}
  cmd.run:
    - name: 'dpkg --remove {{ pkg }}'
{%- endfor %}
