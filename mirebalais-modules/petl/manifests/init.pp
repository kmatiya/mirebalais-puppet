class petl (
  $petl                        = hiera("petl"),
  $petl_home_dir               = hiera("petl_home_dir"),
  $petl_site                   = hiera('petl_site'),
  $petl_version                = hiera("petl_version"),
  $petl_java_home              = hiera("petl_java_home"),
  $petl_java_opts              = hiera("petl_java_opts"),
  $petl_server_port            = hiera("petl_server_port"),
  $petl_config_dir             = hiera("petl_config_dir"),
  $petl_mysql_host             = hiera("petl_mysql_host"),
  $petl_mysql_port             = hiera("petl_mysql_port"),
  $petl_mysql_databaseName     = hiera("petl_mysql_databaseName"),
  $petl_mysql_options          = hiera("petl_mysql_options"),
  $petl_mysql_user             = decrypt(hiera("petl_mysql_user")),
  $petl_mysql_password         = decrypt(hiera("petl_mysql_password")),
  $petl_sqlserver_host             = hiera("petl_sqlserver_host"),
  $petl_sqlserver_port             = hiera("petl_sqlserver_port"),
  $petl_sqlserver_databaseName     = hiera("petl_sqlserver_databaseName"),
  $petl_sqlserver_user             = decrypt(hiera("petl_sqlserver_user")),
  $petl_sqlserver_password         = decrypt(hiera("petl_sqlserver_password")),
  $petl_check_errors_cron_hour     = hiera("petl_check_errors_cron_hour"),
  $petl_error_subject              = hiera("petl_error_subject"),
  $sysadmin_email                  = hiera("sysadmin_email"),
  $petl_config_name                = hiera('petl_config_name'),
  $petl_config_version             = hiera('petl_config_version'),
  $petl_cron_time                  = hiera('petl_cron_time'),
  $petl_hiv_cron_time              = hiera('petl_hiv_cron_time'),
  $imb_etl                         = hiera('imb_etl'),
  $repo_url                        = decrypt(hiera('repo_url')),
) {

  # Setup User, and Home Directory for PETL installation
  user { "$petl":
    ensure  => "present",
    home    => "$petl_home_dir",
    shell   => "/bin/bash"
  }

  file { "${petl_home_dir}":
    ensure  => directory,
    owner   => "$petl",
    group   => "$petl",
    mode    => "0755",
    require => User["$petl"]
  }

  # Setup work and data directories

  file { "${petl_home_dir}/data":
    ensure  => directory,
    owner   => "$petl",
    group   => "$petl",
    mode    => "0755",
    require => File["${petl_home_dir}"]
  }

  file { "${petl_home_dir}/work":
    ensure  => directory,
    owner   => "$petl",
    group   => "$petl",
    mode    => "0755",
    require => File["$petl_home_dir"]
  }

  # Setup application binaries

  file { "$petl_home_dir/bin":
    ensure  => directory,
    owner   => "$petl",
    group   => "$petl",
    mode    => "0755",
    require => File["$petl_home_dir"]
  }

  wget::fetch { "download-petl-jar":
    source      => "http://bamboo.pih-emr.org/artifacts/petl-$petl_version.jar",
    destination => "$petl_home_dir/bin/petl-$petl_version.jar",
    timeout     => 0,
    verbose     => false,
    redownload => true,
    require => File["$petl_home_dir/bin"]
  }

  file { "$petl_home_dir/bin/petl-$petl_version.jar":
    ensure  => present,
    owner   => $petl,
    group   => $petl,
    mode    => "0755",
    require => Wget::Fetch['download-petl-jar']
  }

  file { "$petl_home_dir/bin/petl.jar":
    ensure  => link,
    target => "$petl_home_dir/bin/petl-$petl_version.jar",
    require => File["$petl_home_dir/bin/petl-$petl_version.jar"],
    notify => Exec['petl-restart']
  }

  # remove any old versions of PETL
  exec { "rm -f $(find . -maxdepth 1 -type f -name 'petl-*.jar' ! -name 'petl-$petl_version.jar')":
    require => File["$petl_home_dir/bin/petl.jar"]
  }

  file { "$petl_home_dir/bin/petl.conf":
    ensure  => present,
    content => template("petl/petl.conf.erb"),
    owner   => $petl,
    group   => $petl,
    mode    => "0755",
    require => File["$petl_home_dir/bin/petl.jar"]
  }
    file { "$petl_home_dir/bin/application.yml":
      ensure  => present,
      content => template("petl/application-${petl_site}.yml.erb"),
      owner   => $petl,
      group   => $petl,
      mode    => "0755",
      require => File["$petl_home_dir/bin/petl.jar"],
      notify  => Exec['petl-restart']
    }

  # Set up scripts and services to execute PETL

  # TODO: This requires openjdk-8-jdk to be installed

  file { "/etc/init.d/$petl" :
    ensure => 'link',
    target => "$petl_home_dir/bin/petl.jar",
    require => [ File["$petl_home_dir/bin/petl.conf"], File["$petl_home_dir/bin/petl.jar"] ]
  }

  exec { 'petl-startup-enable':
    command     => "/usr/sbin/update-rc.d -f $petl defaults 81",
    user        => 'root',
    require => File["/etc/init.d/$petl"]
  }

  # make sure PETL is installed, but stopped... we will start it after we install the config
  service { $petl:
    ensure  => stopped,
    enable  => true,
    require => Exec["petl-startup-enable"]
  }

  # petl configuration
  exec { "delete-petl-config-dir":
      command => "rm -rf ${petl_home_dir}/${petl_config_dir}"
  }

  if $imb_etl  {
    vcsrepo { "${petl_home_dir}/${petl_config_dir}":
      ensure   => latest,
      provider => git,
      source      => "https://github.com/PIH/pih-pentaho",
      require => [Service["$petl"], Exec["delete-petl-config-dir"]],
      notify => Exec['petl-restart']
    }
  }
  else {
    if ('SNAPSHOT' in $petl_config_version) {
      $petl_config_repo = "snapshots"
    }
    else {
      $petl_config_repo = "releases"
    }
    if ('apzu-etl' in $petl_config_name) {
      wget::fetch { 'download-azpu-petl-config-dir':
      source      => "https://s01.oss.sonatype.org/service/local/artifact/maven/content?g=org.pih.openmrs&a=${petl_config_name}&r=${petl_config_repo}&c=distribution&p=zip&v=${petl_config_version}",
      destination => "/tmp/petl-${petl_config_name}.zip",
      timeout     => 0,
      verbose     => false,
      redownload  => true,
      }
      exec { 'install-apzu-petl-config-dir':
      command => "rm -rf /tmp/petl_configuration && unzip -o /tmp/petl-${petl_config_name}.zip -d /tmp/petl_configuration && rm -rf ${petl_home_dir}/${petl_config_dir} && mkdir -p ${petl_home_dir}/${petl_config_dir} && cp -r /tmp/petl_configuration/* ${petl_home_dir}/${petl_config_dir} && chown -R ${petl}:${petl} ${petl_home_dir}",
      require => [ Wget::Fetch['download-azpu-petl-config-dir'], Package['unzip'], Service["$petl"]],
      notify  => Exec['petl-restart']
      }
    }
    else {
      wget::fetch { 'download-petl-config-dir':
      source => "https://s01.oss.sonatype.org/service/local/artifact/maven/content?g=org.pih.openmrs&a=${petl_config_name}&r=${petl_config_repo}&p=zip&v=${petl_config_version}",
      destination => "/tmp/petl-${petl_config_name}.zip",
      timeout    => 0,
      verbose    => false,
      redownload => true,
        }
      exec { 'install-petl-config-dir':
      command => "rm -rf /tmp/petl_configuration && unzip -o /tmp/petl-${petl_config_name}.zip -d /tmp/petl_configuration && rm -rf ${petl_home_dir}/${petl_config_dir} && mkdir -p ${petl_home_dir}/${petl_config_dir} && cp -r /tmp/petl_configuration/pih/petl/* ${petl_home_dir}/${petl_config_dir} && chown -R ${petl}:${petl} ${petl_home_dir}",
      require => [ Wget::Fetch['download-petl-config-dir'], Package['unzip'], Service["$petl"]],
      notify  => Exec['petl-restart']
      }
    }
  }

    # just restart PETL every time the deploy runs
    exec { 'petl-restart':
      command => "service $petl start",
      user    => 'root',
      require => Service["$petl"],
    }

    ## logrotate
    file { "/etc/logrotate.d/petl-${petl_site}":
      ensure  => file,
      content => template('petl/logrotate.erb')
    }

    # Petl error file
    file { "/usr/local/sbin/petl-${petl_site}-checkErrors.sh":
      ensure  => present,
      content => template('petl/checkPetlErrors.sh.erb'),
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File["$petl_home_dir/bin"]
    }

    cron { 'petl-error':
      ensure  => present,
      command => "/usr/local/sbin/petl-${petl_site}-checkErrors.sh &> /dev/null",
      user    => 'root',
      hour    => "${petl_check_errors_cron_hour}",
      minute  => 00,
      require => File["/usr/local/sbin/petl-${petl_site}-checkErrors.sh"]

    }

}
