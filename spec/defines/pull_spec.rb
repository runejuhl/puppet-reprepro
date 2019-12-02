require 'spec_helper'

describe 'reprepro::pull' do
  let :default_params do
    {
      basedir: '/var/packages',
    }
  end

  context 'With default parameters' do
    let(:title) { 'lenny-backports' }
    let :params do
      default_params.merge(name: 'lenny-backports',
                           repository: 'localpkgs',
                           from: 'dev')
    end

    fragment         = 'pulls-lenny-backports'
    target           = '/var/packages/localpkgs/conf/pulls'

    it do
      is_expected.to contain_concat__fragment(fragment).with(target: target)
    end
  end
end
