{% set client = '' %}
{% set hostname = '' %}

{% set domain = '' %}

{% set appname = 'phpmyadmin' %}
{% set apppass = '!' %}

{% set mysqlpass = '' %}

{% set phpver = '8.0' %}

{% set appdir = '/var/www/' ~ appname ~ '/app' %}
{% set logdir = appdir ~ '/logs' %}

percona:
  databases:
    {{ appname }}:
  users:
    {{ appname }}:
      host: localhost
      password: '{{ mysqlpass }}'
      databases:
        - database: {{ appname }}
          grant: ['all privileges']

app:
  php-fpm_apps:
    {{ appname }}:
      enabled: True
      user: '{{ appname }}'
      group: '{{ appname }}'
      pass: '{{ apppass }}'
      enforce_password: True
      app_root: '/var/www/{{ appname }}'
      app_auth_keys: |
      shell: '/usr/bin/nologin'
      nginx:
        link_sites-enabled: True
        reload: False
        vhost_config: 'app/{{ client }}/{{ hostname }}/{{ appname }}/vhost.conf'
        root: '{{ appdir }}/src'
        server_name: '{{ domain }}'
        access_log: '{{ logdir }}/nginx/{{ appname }}.access.log'
        error_log: '{{ logdir }}/nginx/{{ appname }}.error.log'
        log:
          dir: '{{ logdir }}/nginx'
        ssl:
          acme: True
      pool:
        pool_config: 'app/{{ client }}/{{ hostname }}/{{ appname }}/pool.conf'
        reload: False
        log:
          dir: '{{ logdir }}'
        php_version: '{{ phpver }}'
        pm: |
          pm = dynamic
          pm.max_children = 20
          pm.start_servers = 5
          pm.min_spare_servers = 5
          pm.max_spare_servers = 10
        php_admin: |
          php_admin_value[error_log] = {{ logdir }}/{{ phpver }}-fpm/{{ appname }}.error.log
          php_admin_value[upload_max_filesize] = 100M
          php_admin_value[post_max_size] = 100M
          request_terminate_timeout = 300
          php_admin_flag[html_errors] = off
          php_admin_flag[log_errors] = on
          php_flag[display_errors] = off
          php_admin_value[memory_limit] = 512M
      files:
        src: app/{{ client }}/{{ hostname }}/{{ appname }}/setup
        dst: /var/www/{{ appname }}/app/setup
      setup_script:
        cwd: /var/www/{{ appname }}/app
        name: bash /var/www/{{ appname }}/app/setup/phpmyadmin-setup.bash
