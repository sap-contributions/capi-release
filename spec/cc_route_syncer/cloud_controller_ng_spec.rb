# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

module Bosh::Template::Test
  describe 'cloud_controller_ng job template rendering' do
    let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
    let(:release) { ReleaseDir.new(release_path) }
    let(:job) { release.job('cc_route_syncer') }
    let(:temporary_internal_domains) { [] }
    let(:merged_manifest_properties) do
      {
        'ccdb' =>
          { 'databases' => [ {'tag' => 'cc' }],
            'port' => 3306,
            'roles' =>
              [{ 'password' => '((the_sanitized_password))',
                 'tag' => 'admin' }] },
      }
    end
    let(:db_link) do
      Link.new(name: 'database',
               instances: [LinkInstance.new(address: 'some-database-address')])
    end

    let(:internal_properties) do
      {
        'cc' => {
          'database_encryption' => {'experimental_pbkdf2_hmac_iterations' => 'wow'},
          'logging' => {'format' => {'timestamp' => 'rfc3339'}},
        },
        'copilot' => {
            'enabled' => true,
            'host' => 'neopets.com',
            'temporary_istio_domains' => temporary_internal_domains
        }
      }
    end
    let(:internal_link) do
      Link.new(name: 'cloud_controller_internal',
               properties: internal_properties)
    end
    let(:cc_networking_link) do
      Link.new(name: 'cloud_controller_container_networking_info',
               properties: {'cc' => {'internal_route_vip_range' => '127.128.0.0/9'}})
    end

    let(:copilot_link) do
      Link.new(
          name: 'cloud_controller_to_copilot_conn',
          properties: {
              'listen_port_for_cloud_controller' => 12345
          }
      )
    end

    let(:links) { [db_link, internal_link, cc_networking_link, copilot_link] }

    describe 'config/cloud_controller_ng.yml' do
      let(:template) { job.template('config/cloud_controller_ng.yml') }

      it 'creates the cloud_controller_ng.yml config file' do
        expect do
          YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
        end.to_not raise_error
      end

      describe 'internal route vip range' do
        it 'has a default range' do
          rendered_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
          expect(rendered_hash['internal_route_vip_range']).to eq('127.128.0.0/9')
        end

        describe 'when a range is specified in manifest properties' do
          it 'validates they are valid CIDRs' do
            cc_networking_link.properties['cc']['internal_route_vip_range'] = '10.16.255.0/777'
            expect { YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            }.to raise_error(StandardError, 'invalid cc.internal_route_vip_range: 10.16.255.0/777')
          end

          it 'does not allow ipv6 addresses' do
            cc_networking_link.properties['cc']['internal_route_vip_range'] = '2001:0db8:85a3:0000:0000:8a2e:0370:7334/21'
            expect { YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            }.to raise_error(StandardError, 'invalid cc.internal_route_vip_range: 2001:0db8:85a3:0000:0000:8a2e:0370:7334/21')
          end

          it 'renders valid CIDRs' do
            cc_networking_link.properties['cc']['internal_route_vip_range'] = '10.16.255.0/24'
            rendered_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            expect(rendered_hash['internal_route_vip_range']).to eq('10.16.255.0/24')
          end
        end
      end

      describe 'temporary_istio_domains' do
        context 'when an entry is an array of domains' do
          let(:temporary_internal_domains) do
            [
                'brook-sentry.capi.land',
                [
                    'mesh.apps.internal',
                    'mesh.apps.other.internal'
                ]
            ]
          end

          it 'flattens the array of domains' do
            template_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            expect(template_hash['copilot']['temporary_istio_domains']).to eq([
                                                                                  'brook-sentry.capi.land',
                                                                                  'mesh.apps.internal',
                                                                                  'mesh.apps.other.internal'
                                                                              ])
          end
        end
      end
    end
  end
end
