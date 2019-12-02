#
# Import a PGP key into the local keyring of the reprepro user
#
# @param key_source
#   Path to the key in gpg --export format. This is
#   used as the source parameter in a puppet File resource.
# @param key_content
#   define the key content instead of pointing to a source file
#
define reprepro::key (
  String $key_source  = '',
  String $key_content = '',
) {

  include reprepro

  $keypath = "${reprepro::homedir}/.gnupg/${name}"

  if $key_source == $key_content {
    fail('You have to specify key_source or key_content')
  }

  if $key_source != '' {
    file {$keypath:
      ensure  => 'present',
      owner   => $::reprepro::user_name,
      group   => $::reprepro::group_name,
      mode    => '0660',
      source  => $key_source,
      require => User[$::reprepro::user_name],
      notify  => Exec["import-${name}"],
    }
  }

  if $key_content != '' {
    file {$keypath:
      ensure  => 'present',
      owner   => $::reprepro::user_name,
      group   => $::reprepro::group_name,
      mode    => '0660',
      content => $key_content,
      require => User[$::reprepro::user_name],
      notify  => Exec["import-${name}"],
    }
  }

  exec {"import-${name}":
    path        => ['/usr/local/bin', '/usr/bin', '/bin'],
    command     => "su -c 'gpg --import ${keypath}' ${::reprepro::user_name}",
    refreshonly => true,
  }
}
