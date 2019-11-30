require 'spec_helper'

describe 'reprepro::update' do
  let :default_params do
    {
      basedir: '/var/packages',
      name: 'lenny-backports',
      suite: 'lenny',
      repository: 'dev',
      url: 'http://backports.debian.org/debian-backports',
      ignore_release: 'No',
    }
  end

  context 'With default params' do
    let(:title) { 'lenny-backports' }
    let(:params) do
      default_params
    end

    fragment         = 'update-lenny-backports'
    target           = '/var/packages/dev/conf/updates'

    it { is_expected.to contain_class('reprepro::params') }

    it do
      is_expected.to contain_concat__fragment(fragment).with(target: target)
    end
  end
end
