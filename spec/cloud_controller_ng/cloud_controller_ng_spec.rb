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
    let(:job) { release.job('cloud_controller_ng') }

    let(:merged_manifest_properties) do
      {
        'app_domains' =>
          ['brook-sentry.capi.land',
           { 'internal' => true, 'name' => 'foo.brook-sentry.capi.land' }],
        'app_ssh' =>
          { 'host_key_fingerprint' =>
            '((diego_ssh_proxy_host_key.public_key_fingerprint))' },
        'cc' =>
          { 'buildpacks' =>
            { 'blobstore_type' => 'webdav',
              'webdav_config' =>
                { 'blobstore_timeout' => 5,
                  'ca_cert' => '((service_cf_internal_ca.certificate))',
                  'password' => '((blobstore_admin_users_password))',
                  'private_endpoint' => 'https://blobstore.service.cf.internal:4443',
                  'public_endpoint' => 'https://blobstore.brook-sentry.capi.land',
                  'username' => 'blobstore-user' } },
            'bulk_api_password' => '((cc_bulk_api_password))',
            'database_encryption' =>
              { 'current_key_label' => 'encryption_key_0',
                'keys' => { 'encryption_key_0' => '((cc_db_encryption_key))' } },
            'db_encryption_key' => '((cc_db_encryption_key))',
            'default_app_memory' => 256,
            'default_running_security_groups' =>
              %w[public_networks dns load_balancer],
            'default_staging_security_groups' => %w[public_networks dns],
            'droplets' =>
              { 'blobstore_type' => 'webdav',
                'webdav_config' =>
                  { 'blobstore_timeout' => 5,
                    'ca_cert' => '((service_cf_internal_ca.certificate))',
                    'password' => '((blobstore_admin_users_password))',
                    'private_endpoint' => 'https://blobstore.service.cf.internal:4443',
                    'public_endpoint' => 'https://blobstore.brook-sentry.capi.land',
                    'username' => 'blobstore-user' } },
            'install_buildpacks' =>
              [{ 'name' => 'staticfile_buildpack', 'package' => 'staticfile-buildpack' },
               { 'name' => 'java_buildpack', 'package' => 'java-buildpack' },
               { 'name' => 'ruby_buildpack', 'package' => 'ruby-buildpack' },
               { 'name' => 'dotnet_core_buildpack', 'package' => 'dotnet-core-buildpack' },
               { 'name' => 'nodejs_buildpack', 'package' => 'nodejs-buildpack' },
               { 'name' => 'go_buildpack', 'package' => 'go-buildpack' },
               { 'name' => 'python_buildpack', 'package' => 'python-buildpack' },
               { 'name' => 'php_buildpack', 'package' => 'php-buildpack' },
               { 'name' => 'binary_buildpack', 'package' => 'binary-buildpack' }],
            'internal_api_password' => '((cc_internal_api_password))',
            'mutual_tls' =>
              { 'ca_cert' => '((service_cf_internal_ca.certificate))',
                'private_key' => '((cc_tls.private_key))',
                'public_cert' => '((cc_tls.certificate))' },
            'packages' =>
              { 'blobstore_type' => 'webdav',
                'webdav_config' =>
                  { 'blobstore_timeout' => 5,
                    'ca_cert' => '((service_cf_internal_ca.certificate))',
                    'password' => '((blobstore_admin_users_password))',
                    'private_endpoint' => 'https://blobstore.service.cf.internal:4443',
                    'public_endpoint' => 'https://blobstore.brook-sentry.capi.land',
                    'username' => 'blobstore-user' } },
            'resource_pool' =>
              { 'blobstore_type' => 'webdav',
                'webdav_config' =>
                  { 'blobstore_timeout' => 5,
                    'ca_cert' => '((service_cf_internal_ca.certificate))',
                    'password' => '((blobstore_admin_users_password))',
                    'private_endpoint' => 'https://blobstore.service.cf.internal:4443',
                    'public_endpoint' => 'https://blobstore.brook-sentry.capi.land',
                    'username' => 'blobstore-user' } },
            'security_group_definitions' =>
              [{ 'name' => 'public_networks',
                 'rules' =>
                  [{ 'destination' => '0.0.0.0-9.255.255.255', 'protocol' => 'all' },
                   { 'destination' => '11.0.0.0-169.253.255.255', 'protocol' => 'all' },
                   { 'destination' => '169.255.0.0-172.15.255.255', 'protocol' => 'all' },
                   { 'destination' => '172.32.0.0-192.167.255.255', 'protocol' => 'all' },
                   { 'destination' => '192.169.0.0-255.255.255.255', 'protocol' => 'all' }] },
               { 'name' => 'dns',
                 'rules' =>
                   [{ 'destination' => '0.0.0.0/0', 'ports' => '53', 'protocol' => 'tcp' },
                    { 'destination' => '0.0.0.0/0', 'ports' => '53', 'protocol' => 'udp' }] },
               { 'name' => 'load_balancer',
                 'rules' => [{ 'destination' => '10.244.0.34', 'protocol' => 'all' }] }],
            'stacks' =>
              [{ 'description' => 'Cloud Foundry Linux-based filesystem',
                 'name' => 'cflinuxfs2' }],
            'staging_upload_password' => '((cc_staging_upload_password))',
            'staging_upload_user' => 'staging_user' },
        'ccdb' =>
          { 'databases' => [{ 'name' => 'cloud_controller', 'tag' => 'cc' }],
            'db_scheme' => 'mysql',
            'port' => 3306,
            'roles' =>
              [{ 'name' => 'cloud_controller',
                 'password' => '((cc_database_password))',
                 'tag' => 'admin' }] },
        'router' => { 'route_services_secret' => '((router_route_services_secret))' },
        'routing_api' => { 'enabled' => true },
        'ssl' => { 'skip_cert_verify' => true },
        'system_domain' => 'brook-sentry.capi.land',
        'uaa' =>
          { 'ca_cert' => '((uaa_ca.certificate))',
            'clients' =>
              { 'cc-service-dashboards' =>
                { 'secret' => '((uaa_clients_cc-service-dashboards_secret))' },
                'cc_routing' => { 'secret' => '((uaa_clients_cc-routing_secret))' },
                'cc_service_key_client' =>
                  { 'secret' => '((uaa_clients_cc_service_key_client_secret))' },
                'cloud_controller_username_lookup' =>
                  { 'secret' => '((uaa_clients_cloud_controller_username_lookup_secret))' } },
            'url' => 'https://uaa.brook-sentry.capi.land' }
      }
    end

    let(:db_link) do
      Link.new(name: 'database', instances: [LinkInstance.new(address: 'some-other-database-address')])
    end

    let(:links) { [db_link] }

    describe 'config/cloud_controller_ng.yml' do
      let(:template) { job.template('config/cloud_controller_ng.yml') }

      it 'creates the cloud_controller_ng.yml config file' do
        expect do
          YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
        end.to_not raise_error
      end

      describe 'app_domains' do
        it 'accepts a list of domain hashes and domain strings' do
          template_hash = YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
          expect(template_hash['app_domains']).to eq([
            'brook-sentry.capi.land',
            { 'internal' => true, 'name' => 'foo.brook-sentry.capi.land' }
          ])
        end

        context 'when a domain is marked internal and a router group specified' do
          before do
            merged_manifest_properties['app_domains'] = [
              { 'internal' => true, 'name' => 'foo.brook-sentry.capi.land', 'router_group_name' => 'tcp-router' }
            ]
          end

          it 'raises an error' do
            expect do
              YAML.safe_load(template.render(merged_manifest_properties, consumes: links))
            end.to raise_error(StandardError, 'Error for app_domains: Router groups cannot be specified for internal domains.')
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
