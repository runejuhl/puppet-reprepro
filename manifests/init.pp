#
# Configures reprepro on a server
#
# @param basedir
#   The base directory to house the repository.
# @param homedir
#   The home directory of the reprepro user.
# @param manage_user
#   if true, creates the user $user_name
# @param user_name
#   user_name who own reprepro
# @param group_name
#   group of user who own reprepro
# @param keys
#   hash to create reprepro::key resources.
# @param key_defaults
#   hash with defaults for keys creation.
# @param package_ensure
#   what to ensure for packages
# @param package_name
#   name of the package to install
#
class reprepro (
  String  $basedir        = '/var/packages',
  String  $homedir        = '/var/packages',
  Boolean $manage_user    = true,
  String  $user_name      = 'reprepro',
  String  $group_name     = 'reprepro',
  Hash    $keys           = {},
  Hash    $key_defaults   = {},
  String  $package_ensure = 'present',
  String  $package_name   = 'reprepro',
) {
  validate_bool($manage_user)

  package { $package_name:
    ensure => $package_ensure,
  }

  if $manage_user {
    group { $group_name:
      ensure => present,
      name   => $group_name,
      system => true,
    }

    user { $user_name:
      ensure     => present,
      name       => $user_name,
      home       => $homedir,
      shell      => '/bin/bash',
      comment    => 'Reprepro user',
      gid        => $group_name,
      managehome => true,
      system     => true,
      require    => Group[$group_name],
      notify     => [
        File["${homedir}/.gnupg"],
        File["${homedir}/bin"],
      ],
    }
  }

  if ($basedir != $homedir) {
    file { $basedir:
      ensure  => directory,
      owner   => $user_name,
      group   => $group_name,
      mode    => '0755',
      require => User[$user_name],
    }
  }

  file { "${homedir}/.gnupg":
    ensure => directory,
    owner  => $user_name,
    group  => $group_name,
    mode   => '0700',
  }

  file { "${homedir}/bin":
    ensure => directory,
    mode   => '0755',
    owner  => $user_name,
    group  => $group_name,
  }

  file { "${homedir}/bin/update-distribution.sh":
    ensure  => file,
    mode    => '0755',
    content => template('reprepro/update-distribution.sh.erb'),
    owner   => $user_name,
    group   => $group_name,
  }

  concat { "${homedir}/bin/update-all-repositories.sh":
    owner => $user_name,
    group => $group_name,
    mode  => '0755',
  }
  concat::fragment{'update-repositories header':
    target  => "${homedir}/bin/update-all-repositories.sh",
    content => "#!/bin/sh\n# Managed with puppet (module: reprepro)\n\n",
    order   => '0',
  }

  create_resources('::reprepro::key', $keys, $key_defaults)
}
