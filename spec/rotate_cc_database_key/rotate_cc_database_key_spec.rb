# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

# rubocop:disable Metrics/BlockLength
module Bosh::Template::Test
  describe 'cloud_controller_ng job template rendering' do
    let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
    let(:release) { ReleaseDir.new(release_path) }
    let(:job) { release.job('rotate_cc_database_key') }

    let(:manifest_properties) do
      {
        'cc' => {
          'db_logging_level' => 100
        }
      }
    end

    let(:properties) do
      {
        'cc' => {
          'logging_max_retries' => 'bar1',
          'default_app_ssh_access' => 'something',
          'logging_level' => 'other thing',
          'log_db_queries' => 'balsdkj',
          'db_logging_level' => 'bar2',
          'db_encryption_key' => 'bar3',
          'database_encryption' => {
            'experimental_pbkdf2_hmac_iterations' => 123,
            'skip_validation' => false,
            'current_key_label' => 'encryption_key_0',
            'keys' => { 'encryption_key_0' => '((cc_db_encryption_key))' }
          }
        }
      }
    end
    let(:cloud_controller_internal_link) do
      Link.new(name: 'cloud_controller_internal', properties: properties, instances: [LinkInstance.new(address: 'default_app_ssh_access')])
    end

    let(:cloud_controller_db_link) do
      properties = {
        'ccdb' => {
          'db_scheme' => 'mysql',
          'max_connections' => 'foo2',
          'databases' => [{ 'tag' => 'cc' }],
          'roles' => [{
            'tag' => 'admin',
            'name' => 'alex',
            'password' => 'pass'
          }],
          'address' => 'foo5',
          'port' => 'foo7',
          'pool_timeout' => 'foo11',
          'ssl_verify_hostname' => 'foo12',
          'read_timeout' => 'foo13',
          'connection_validation_timeout' => 'foo14',
          'ca_cert' => 'foo15'
        }
      }
      Link.new(name: 'cloud_controller_db', properties: properties, instances: [LinkInstance.new(address: 'cloud_controller_db')])
    end

    let(:links) { [cloud_controller_internal_link, cloud_controller_db_link] }

    describe 'config/cloud_controller_ng.yml' do
      let(:template) { job.template('config/cloud_controller_ng.yml') }

      it 'creates the cloud_controller_ng.yml config file' do
        expect do
          YAML.safe_load(template.render(manifest_properties, consumes: links))
        end.to_not raise_error
      end

      describe 'database_encryption block' do
        context 'when the database_encryption block is not present' do
          before do
            properties['cc'].delete('database_encryption')
          end

          it 'does not raise an error' do
            expect do
              YAML.safe_load(template.render(manifest_properties, consumes: links))
            end.to_not raise_error
          end
        end

        context 'when the "current_encryption_key_label" is not found in the "keys" map' do
          before do
            properties['cc']['database_encryption']['current_key_label'] = 'encryption_key_label_not_here_anymore'
          end

          context 'when the skip validation property is false' do
            it 'raises an error' do
              expect do
                YAML.safe_load(template.render(manifest_properties, consumes: links))
              end.to raise_error(
                StandardError,
                "Error for database_encryption: 'current_key_label' set to 'encryption_key_label_not_here_anymore', but not present in 'keys' map."
              )
            end
          end

          context 'when the skip validation property is true' do
            before do
              properties['cc']['database_encryption']['skip_validation'] = true
            end

            it 'does not raise an error' do
              expect do
                YAML.safe_load(template.render(manifest_properties, consumes: links))
              end.to_not raise_error
            end
          end
        end

        context 'when the database_encryption.keys block is an array with secrets' do
          before do
            properties['cc']['database_encryption']['keys'] = [
              {
                'encryption_key' => 'blah',
                'label' => 'encryption_key_0',
                'active' => false,
              },
              {
                'encryption_key' => 'other_key',
                'label' => 'encryption_key_1',
                'active' => true,
              }
            ]
          end

          it 'converts the array into the expected format (hash)' do
            template_hash = YAML.safe_load(template.render(manifest_properties, consumes: links))
            expect(template_hash['database_encryption']['keys']).to eq({
              'encryption_key_0' => 'blah',
              'encryption_key_1' => 'other_key'
            })
            expect(template_hash['database_encryption']['current_key_label']).to eq('encryption_key_1')
          end
        end

        context 'when the database_encryption.keys block is a hash' do
          before do
            properties['cc']['database_encryption']['keys'] = {
              'encryption_key_0' => 'blah',
              'encryption_key_1' => 'other_key'
            }
          end

          it 'converts the array into the expected format (hash)' do
            template_hash = YAML.safe_load(template.render(manifest_properties, consumes: links))
            expect(template_hash['database_encryption']['keys']).to eq({
              'encryption_key_0' => 'blah',
              'encryption_key_1' => 'other_key'
            })
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
