#
# Adds a packages repository.
#
# @param name
#   the name of the repository
# @param ensure
#   present/absent, defaults to present
# @param incoming_name
#   the name of the rule-set, used as argument
# @param incoming_dir
#   the name of the directory to scan for .changes files
# @param incoming_tmpdir
#   directory where the files are copied into
#   before they are read
# @param incoming_allow
#   allowed distributions
# @param options
#   reprepro options
# @param createsymlinks
#   create suite symlinks
# @param documentroot
#   documentroot of the webserver (default undef)
#   if set, softlinks to the reprepro directories are made
#   the directory $documentroot must already exist
#
# @example
#   reprepro::repository { 'localpkgs':
#     ensure  => present,
#     options => ['verbose', 'basedir .'],
#   }
#
define reprepro::repository (
  String                 $ensure          = 'present',
  String                 $incoming_name   = 'incoming',
  String                 $incoming_dir    = 'incoming',
  String                 $incoming_tmpdir = 'tmp',
  Variant[String, Array] $incoming_allow  = '',
  Array                  $options         = ['verbose', 'ask-passphrase', 'basedir .'],
  Boolean                $createsymlinks  = false,
  Optional[String]       $documentroot    = undef,
) {

  include reprepro

  if $incoming_allow =~ Array {
    $_incoming_allow = $incoming_allow.join(' ')
  } else {
    $_incoming_allow = $incoming_allow
  }

  if $ensure == 'absent' {
    $directory_ensure = 'absent'
  } else {
    $directory_ensure = 'directory'
  }

  file { "${reprepro::basedir}/${name}":
    ensure  => $directory_ensure,
    purge   => true,
    recurse => true,
    force   => true,
    mode    => '2755',
    owner   => $reprepro::user_name,
    group   => $reprepro::group_name,
  }

  file {
    [ "${reprepro::basedir}/${name}/dists",
      "${reprepro::basedir}/${name}/pool",
      "${reprepro::basedir}/${name}/conf",
      "${reprepro::basedir}/${name}/lists",
      "${reprepro::basedir}/${name}/db",
      "${reprepro::basedir}/${name}/logs",
      "${reprepro::basedir}/${name}/tmp",
    ]:
    ensure => $directory_ensure,
    mode   => '2755',
    owner  => $reprepro::user_name,
    group  => $reprepro::group_name,
  }

  file { "${reprepro::basedir}/${name}/incoming":
    ensure => $directory_ensure,
    mode   => '2775',
    owner  => $reprepro::user_name,
    group  => $reprepro::group_name,
  }

  file { "${reprepro::basedir}/${name}/conf/options":
    ensure  => $ensure,
    mode    => '0640',
    owner   => $reprepro::user_name,
    group   => $reprepro::group_name,
    content => inline_template("<%= @options.join(\"\n\") %>\n"),
  }

  file { "${reprepro::basedir}/${name}/conf/incoming":
    ensure  => $ensure,
    mode    => '0640',
    owner   => $reprepro::user_name,
    group   => $reprepro::group_name,
    content => template('reprepro/incoming.erb'),
  }

  concat { "${reprepro::basedir}/${name}/conf/distributions":
    ensure => $ensure,
    owner  => $reprepro::user_name,
    group  => $reprepro::group_name,
    mode   => '0640',
  }

  if $ensure == 'present' {
    concat::fragment { "00-distributions-${name}":
      content => "# Puppet managed\n",
      target  => "${reprepro::basedir}/${name}/conf/distributions",
    }
    concat::fragment { "00-update-${name}":
      content => "# Puppet managed\n",
      target  => "${reprepro::basedir}/${name}/conf/updates",
    }
    concat::fragment { "00-pulls-${name}":
      content => "# Puppet managed\n",
      target  => "${reprepro::basedir}/${name}/conf/pulls",
    }
    concat::fragment{"update-repositories add repository ${name}":
      target  => "${reprepro::homedir}/bin/update-all-repositories.sh",
      content => "echo\necho 'updatating ${name}:'\n/usr/bin/reprepro -b ${reprepro::basedir}/${name} --noskipold update\n",
      order   => "50-${name}",
    }
  }

  concat { "${reprepro::basedir}/${name}/conf/updates":
    ensure => $ensure,
    owner  => $reprepro::user_name,
    group  => $reprepro::group_name,
    mode   => '0640',
  }

  concat {"${reprepro::basedir}/${name}/conf/pulls":
    ensure => $ensure,
    owner  => root,
    group  => root,
    mode   => '0644',
  }


  if $createsymlinks {
    exec {"${name}-createsymlinks":
      command     => "su -c 'reprepro -b ${reprepro::basedir}/${name} --delete createsymlinks' ${reprepro::owner}",
      refreshonly => true,
      subscribe   => Concat[ "${reprepro::basedir}/${name}/conf/distributions" ];
    }
  }

  if $documentroot {
    # create base-directory and symbolic link to repository for apache
    if $ensure == 'absent' {
      $link_ensure = 'absent'
    } else {
      $link_ensure = 'link'
    }
    file {"${documentroot}/${name}":
      ensure  => $directory_ensure,
    }
    file {"${documentroot}/${name}/dists":
      ensure => $link_ensure,
      target => "${reprepro::basedir}/${name}/dists",
    }
    file {"${documentroot}/${name}/pool":
      ensure => $link_ensure,
      target => "${reprepro::basedir}/${name}/pool",
    }
  }

}
