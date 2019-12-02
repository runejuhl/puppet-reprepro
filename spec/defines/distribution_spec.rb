require 'spec_helper'

describe 'reprepro::distribution' do
  let(:pre_condition) { ['include reprepro', 'reprepro::repository{localpkgs:}'] }
  let :default_params do
    {
      repository: 'localpkgs',
      origin: 'Foobar',
      label: 'Foobar',
      suite: 'precise',
      architectures: 'amd64 i386',
      components: 'main contrib non-free',
      description: 'Package repository for local site maintenance',
      sign_with: 'F4D5DAA8',
      basedir: '/var/packages',
      not_automatic: 'No',
      install_cron: true,
    }
  end

  context 'With default parameters' do
    let(:title) { 'precise' }
    let :params do
      default_params.merge(name: 'precise',
                           codename: 'precise')
    end

    it do
      is_expected.to contain_concat__fragment('distribution-precise').with(target: '/var/packages/localpkgs/conf/distributions').that_notifies('Exec[export distribution precise]')
    end

    it do
      is_expected.to contain_exec('export distribution precise').with(command: "su -c 'reprepro -b /var/packages/localpkgs export precise' reprepro")
    end

    it { is_expected.to contain_file('/var/packages/localpkgs/tmp/precise') }
    it { is_expected.to contain_cron('precise cron') }
  end
end
