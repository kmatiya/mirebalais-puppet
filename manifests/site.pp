node default {
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
  include mirebalais

  if $environment != 'test' {
    include mirebalais_logging
  }

}
