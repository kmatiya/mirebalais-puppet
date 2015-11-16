class bahmni_openmrs (
  $openmrs_db = hiera('openmrs_db'),
  $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
  $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
  $openmrs_auto_update_database = hiera('openmrs_auto_update_database'),
  $webapp_name = hiera('webapp_name'),
  $tomcat = hiera('tomcat'),
  $addresshierarchy_version = '2.7',
  $appframework_version = '2.3',
  $appui_version = '1.3',
  $appointmentscheduling_version = '1.4',
  $appointmentschedulingui_version = '1.0.3',
  $calculation_version = '1.1',
  $coreapps_version = '1.7',
  $emrapi_version = '1.13-SNAPSHOT',
  $event_version = '2.2.1',
  $htmlformentry_version = '2.5',
  $htmlformentryui_version = '1.2',
  $htmlwidgets_version = '1.6.4',
  $idgen_version = '4.0',
  $idgen_webservices_version = '1.1-SNAPSHOT',
  $metadatamapping_version = '1.0.2',
  $metadatasharing_version = '1.1.9',
  $providermanagement_version = '2.3',
  $reporting_version = '0.9.6',
  $reportingrest_version = '1.4',
  $serialization_xstream_version = '0.2.7',
  $uicommons_version = '1.7',
  $uiframework_version = '3.4',
  $uilibrary_version = '2.0.4',
  $webservices_rest_version = '2.12',
){

  mysql_database { $openmrs_db :
    ensure  => present,
    require => [Service['mysqld']],
    charset => 'utf8',
  } ->

  mysql_user { "${openmrs_db_user}@localhost":
    ensure        => present,
    password_hash => mysql_password($openmrs_db_password),
    require => [ Service['mysqld']],
  } ->

  mysql_grant { "${openmrs_db_user}@localhost/${openmrs_db}":
    options    => ['GRANT'],
    privileges => ['ALL'],
    table => '*.*',
    user => "${openmrs_db_user}@localhost",
    require => [ Service['mysqld'] ],
  } ->

  mysql_grant { "root@localhost/${openmrs_db}":
    options    => ['GRANT'],
    privileges => ['ALL'],
    table => '*.*',
    user => "root@localhost",
    require => [Service['mysqld'] ],
    notify  => Exec ['tomcat-restart']
  }

  file { '/etc/apt/apt.conf.d/99auth':
    ensure  => present,
    owner   => root,
    group   => root,
    content => 'APT::Get::AllowUnauthenticated yes;',
    mode    => '0644'
  }

  file { "/home/${tomcat}/.OpenMRS":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0755',
    require => User[$tomcat]
  }

  file { "/home/${tomcat}/.OpenMRS/modules":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0755',
    require => File["/home/${tomcat}/.OpenMRS"]
  }


  file { "/home/${tomcat}/.OpenMRS/${webapp_name}-runtime.properties":
    ensure  => present,
    content => template('openmrs/openmrs-runtime.properties.erb'),
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0644',
    require => File["/home/${tomcat}/.OpenMRS"]
  }

  maven { "/usr/local/tomcat7/webapps/openmrs.war":
    groupid => "org.openmrs.web",
    artifactid => "openmrs-webapp",
    version => "1.12.0-SNAPSHOT",
    ensure => "latest",
    packaging => "war",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/${webapp_name}-runtime.properties"], File['/etc/apt/apt.conf.d/99auth'] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/addresshierarchy-${addresshierarchy_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "addresshierarchy-omod",
    version => "${addresshierarchy_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/appointmentscheduling-${appointmentscheduling_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "appointmentscheduling-omod",
    version => "${appointmentscheduling_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/appointmentschedulingui-${appointmentschedulingui_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "appointmentschedulingui-omod",
    version => "${appointmentschedulingui_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/appframework-${appframework_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "appframework-omod",
    version => "${appframework_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/appui-${appui_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "appui-omod",
    version => "${appui_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/calculation-${calculation_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "calculation-omod",
    version => "${calculation_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/coreapps-${coreapps_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "coreapps-omod",
    version => "${coreapps_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/emrapi-${emrapi_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "emrapi-omod",
    version => "${emrapi_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/event-${event_version}.omod":
    groupid => "org.openmrs",
    artifactid => "event-omod",
    version => "${event_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/htmlformentry-${htmlformentry_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "htmlformentry-omod",
    version => "${htmlformentry_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/htmlformentry-${htmlformentryui_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "htmlformentryui-omod",
    version => "${htmlformentryui_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/htmlwidgets-${htmlwidgets_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "htmlwidgets-omod",
    version => "${htmlwidgets_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/idgen-${idgen_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "idgen-omod",
    version => "${idgen_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/idgen-webservices-${idgen_webservices_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "idgen-webservices-omod",
    version => "${idgen_webservices_version}",
    ensure => "latest",
    packaging => "jar",
    repos => [ "http://bahmnirepo.thoughtworks.com/artifactory/libs-snapshot-local","http://bahmnirepo.thoughtworks.com/artifactory/libs-release-local" ],
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/metadatamapping-${metadatamapping_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "metadatamapping-omod",
    version => "${metadatamapping_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/metadatasharing-${metadatasharing_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "metadatasharing-omod",
    version => "${metadatasharing_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/providermanagement-${providermanagement_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "providermanagement-omod",
    version => "${providermanagement_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/reporting-${reporting_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "reporting-omod",
    version => "${reporting_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/reportingrest-${reportingrest_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "reportingrest-omod",
    version => "${reportingrest_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/serialization.xstream-${serialization_xstream_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "serialization.xstream-omod",
    version => "${serialization_xstream_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }


  maven { "/home/${tomcat}/.OpenMRS/modules/uicommons-${uicommons_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "uicommons-omod",
    version => "${uicommons_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/uiframework-${uiframework_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "uiframework-omod",
    version => "${uiframework_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/uilibrary-${uilibrary_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "uilibrary-omod",
    version => "${uilibrary_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  maven { "/home/${tomcat}/.OpenMRS/modules/webservices.rest-${webservices_rest_version}.omod":
    groupid => "org.openmrs.module",
    artifactid => "webservices.rest-omod",
    version => "${webservices_rest_version}",
    ensure => "latest",
    packaging => "jar",
    repos => "http://mavenrepo.openmrs.org/nexus/content/repositories/public",
    require => [ Package['maven'], Service[$tomcat], File["/home/${tomcat}/.OpenMRS/modules"] ],
    notify  => Exec['tomcat-restart']
  }

  exec { 'tomcat-restart':
    command     => "service ${tomcat} restart",
    user        => 'root',
    refreshonly => true
  }

}
