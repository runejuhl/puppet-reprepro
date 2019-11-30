#
# Adds a packages repository.
#
# @param name
#   the name of the repository
# @param ensure
#   present/absent, defaults to present
# @param basedir
#   base directory of reprepro
# @param incoming_name
#   the name of the rule-set, used as argument
# @param incoming_dir
#   the name of the directory to scan for .changes files
# @param incoming_tmpdir
#   directory where the files are copied into
#   before they are read
# @param incoming_allow
#   allowed distributions
# @param owner
#   owner of reprepro files
# @param group
#   reprepro files group
# @param options
#   reprepro options
# @param createsymlinks
#   create suite symlinks
#
# @example
#   reprepro::repository { 'localpkgs':
#     ensure  => present,
#     options => ['verbose', 'basedir .'],
#   }
#
define reprepro::repository (
  String                 $ensure          = 'present',
  String                 $basedir         = $::reprepro::basedir,
  String                 $incoming_name   = 'incoming',
  String                 $incoming_dir    = 'incoming',
  String                 $incoming_tmpdir = 'tmp',
  Variant[String, Array] $incoming_allow  = '',
  String                 $owner           = 'reprepro',
  String                 $group           = 'reprepro',
  Array                  $options         = ['verbose', 'ask-passphrase', 'basedir .'],
  Boolean                $createsymlinks  = false,
) {

  if $incoming_allow =~ Array {
    $_incoming_allow = $incoming_allow.join(' ')
  } else {
    $_incoming_allow = $incoming_allow
  }

# lint:ignore:selector_inside_resource
  file { "${basedir}/${name}":
    ensure  => $ensure ? {
      'present' => 'directory',
      default   => $ensure,
    },
    purge   => $ensure ? {
      'present' => undef,
      default   => true,
    },
    recurse => $ensure ? {
      'present' => undef,
      default   => true,
    },
    force   => $ensure ? {
      'present' => undef,
      default   => true,
    },
    mode    => '2755',
    owner   => $owner,
    group   => $group,
  }
# lint:endignore

  file {
    [ "${basedir}/${name}/dists",
      "${basedir}/${name}/pool",
      "${basedir}/${name}/conf",
      "${basedir}/${name}/lists",
      "${basedir}/${name}/db",
      "${basedir}/${name}/logs",
      "${basedir}/${name}/tmp",
    ]:
    ensure => directory,
    mode   => '2755',
    owner  => $owner,
    group  => $group,
  }

  file { "${basedir}/${name}/incoming":
    ensure => directory,
    mode   => '2775',
    owner  => $owner,
    group  => $group,
  }

  file { "${basedir}/${name}/conf/options":
    ensure  => $ensure,
    mode    => '0640',
    owner   => $owner,
    group   => $group,
    content => inline_template("<%= @options.join(\"\n\") %>\n"),
  }

  file { "${basedir}/${name}/conf/incoming":
    ensure  => $ensure,
    mode    => '0640',
    owner   => $owner,
    group   => $group,
    content => template('reprepro/incoming.erb'),
  }

  concat { "${basedir}/${name}/conf/distributions":
    owner => $owner,
    group => $group,
    mode  => '0640',
  }

  concat::fragment { "00-distributions-${name}":
    content => "# Puppet managed\n",
    target  => "${basedir}/${name}/conf/distributions",
  }

  concat { "${basedir}/${name}/conf/updates":
    owner => $owner,
    group => $group,
    mode  => '0640',
  }

  concat::fragment { "00-update-${name}":
    content => "# Puppet managed\n",
    target  => "${basedir}/${name}/conf/updates",
  }

  concat {"${basedir}/${name}/conf/pulls":
    owner => root,
    group => root,
    mode  => '0644',
  }

  concat::fragment { "00-pulls-${name}":
    content => "# Puppet managed\n",
    target  => "${basedir}/${name}/conf/pulls",
  }

  if $createsymlinks {
    exec {"${name}-createsymlinks":
      command     => "su -c 'reprepro -b ${basedir}/${name} --delete createsymlinks' ${owner}",
      refreshonly => true,
      subscribe   => Concat[ "${basedir}/${name}/conf/distributions" ];
    }
  }
}
