# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

module Bosh::Template::Test
  describe 'bbr-cloudcontrollerdb config template rendering' do
    let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
    let(:release) { ReleaseDir.new(release_path) }
    let(:job) { release.job('bbr-cloudcontrollerdb') }

    let(:merged_manifest_properties) { {} }

    let(:ccdb_link_properties) do
      {
        'ccdb' => {
          'databases' => [{ 'name' => 'cloud_controller', 'tag' => 'cc' }],
          'db_scheme' => 'mysql',
          'port' => 3306,
          'roles' => [{ 'name' => 'cloud_controller', 'password' => 'p@ssw0rd', 'tag' => 'admin' }],
          'address' => 'sql-db.service.cf.internal'
        }
      }
    end

    let(:cloud_controller_db_link) do
      Link.new(name: 'cloud_controller_db', instances: [LinkInstance.new(address: 'cc-ng.service.cf.internal')], properties: ccdb_link_properties)
    end

    let(:links) { [cloud_controller_db_link] }

    describe 'config/config.json.erb' do
      let(:template) { job.template('config/config.json') }

      it 'creates the config.json bbr config file' do
        expect do
          YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
        end.to_not raise_error
      end

      describe 'TLS configuration' do
        context 'when there is a ccdb.ca_cert configured' do
          let(:ssl_verify_hostname) { true }
          let(:ccdb_link_properties) do
            {
              'ccdb' => {
                'databases' => [{ 'name' => 'cloud_controller', 'tag' => 'cc' }],
                'db_scheme' => 'mysql',
                'port' => 3306,
                'roles' => [{ 'name' => 'cloud_controller', 'password' => 'p@ssw0rd', 'tag' => 'admin' }],
                'address' => 'sql-db.service.cf.internal',
                'ca_cert' => 'RSA secure CERT',
                'ssl_verify_hostname' => ssl_verify_hostname
              }
            }
          end

          context 'when ccdb.ssl_verify_hostname is true' do
            let(:ssl_verify_hostname) { true }

            it 'configures tls.skip_host_verify to false and includes the ca cert' do
              template_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
              expect(template_hash).to eq({
                'adapter' => 'mysql',
                'database' => 'cloud_controller',
                'host' => 'sql-db.service.cf.internal',
                'password' => 'p@ssw0rd',
                'port' => 3306,
                'tls' => { 'skip_host_verify' => false, 'cert' => { 'ca' => 'RSA secure CERT' } },
                'username' => 'cloud_controller'
              })
            end
          end

          context 'when ccdb.ssl_verify_hostname is false' do
            let(:ssl_verify_hostname) { false }

            it 'configures tls.skip_host_verify to true and includes the ca cert' do
              template_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
              expect(template_hash).to eq({
                'adapter' => 'mysql',
                'database' => 'cloud_controller',
                'host' => 'sql-db.service.cf.internal',
                'password' => 'p@ssw0rd',
                'port' => 3306,
                'tls' => { 'skip_host_verify' => true, 'cert' => { 'ca' => 'RSA secure CERT' } },
                'username' => 'cloud_controller'
              })
            end
          end
        end

        context 'when there is not a ccdb.ca_cert configured' do
          it 'does not add any TLS configuration' do
            template_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            expect(template_hash).to eq({
              'adapter' => 'mysql',
              'database' => 'cloud_controller',
              'host' => 'sql-db.service.cf.internal',
              'password' => 'p@ssw0rd',
              'port' => 3306,
              'username' => 'cloud_controller'
            })
          end
        end
      end
    end
  end
end
