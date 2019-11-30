require 'spec_helper'

describe 'reprepro' do
  let :default_params do
    {
      basedir: '/var/packages',
      homedir: '/var/packages',
    }
  end

  context 'With default parameters' do
    let :params do
      default_params
    end

    it { is_expected.to contain_package('reprepro') }
    it { is_expected.to contain_group('reprepro').with_name('reprepro') }
    it do
      is_expected.to contain_user('reprepro').with(name: 'reprepro',
                                                   home: '/var/packages',
                                                   shell: '/bin/bash',
                                                   comment: 'Reprepro user',
                                                   gid: 'reprepro',
                                                   managehome: true,
                                                   system: true)
        .that_requires('Group[reprepro]')
        .that_notifies('File[/var/packages/.gnupg]')
                                             .that_notifies('File[/var/packages/bin]')
    end

    it do
      is_expected.to contain_file('/var/packages/bin').with(ensure: 'directory',
                                                            mode: '0755',
                                                            owner: 'reprepro',
                                                            group: 'reprepro')
    end

    it do
      is_expected.to contain_file('/var/packages/bin/update-distribution.sh').with(mode: '0755',
                                                                                   content: %r{while getopts},
                                                                                   owner: 'reprepro',
                                                                                   group: 'reprepro').that_requires('File[/var/packages/bin]')
    end
  end

  context 'With non-default parameters' do
    let :params do
      {
        basedir: '/home/packages',
        homedir: '/home/packages',
        user_name: 'apt',
        group_name: 'nogroup',
      }
    end

    it { is_expected.to contain_package('reprepro') }
    it { is_expected.to contain_group('nogroup').with_name('nogroup') }
    it do
      is_expected.to contain_user('apt').with(name: 'apt',
                                              home: '/home/packages',
                                              shell: '/bin/bash',
                                              comment: 'Reprepro user',
                                              gid: 'nogroup',
                                              managehome: true,
                                              system: true)
        .that_requires('Group[nogroup]')
        .that_notifies('File[/home/packages/.gnupg]')
                                        .that_notifies('File[/home/packages/bin]')
    end

    it do
      is_expected.to contain_file('/home/packages/bin').with(ensure: 'directory',
                                                             mode: '0755',
                                                             owner: 'apt',
                                                             group: 'nogroup')
    end

    it do
      is_expected.to contain_file('/home/packages/bin/update-distribution.sh').with(mode: '0755',
                                                                                    content: %r{while getopts},
                                                                                    owner: 'apt',
                                                                                    group: 'nogroup').that_requires('File[/home/packages/bin]')
    end
  end

  context 'With manage_user set to false' do
    let :params do
      default_params.merge(manage_user: false)
    end

    it do
      is_expected.not_to contain_group('reprepro')
      is_expected.not_to contain_user('reprepro')
    end
  end

  context 'With manage_user set to an invalid value' do
    let :params do
      default_params.merge(manage_user: 'a string')
    end

    it do
      is_expected.to raise_error(Puppet::Error, %r{is not a boolean})
    end
  end
end
