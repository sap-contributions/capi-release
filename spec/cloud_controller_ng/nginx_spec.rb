# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'

module Bosh
  module Template
    module Test
      describe 'nginx config template rendering' do
        let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
        let(:release) { ReleaseDir.new(release_path) }
        let(:job) { release.job('cloud_controller_ng') }

        describe 'nginx.conf' do
          let(:template) { job.template('config/nginx.conf') }
          let(:manifest_properties) { {} }

          before do
            @rendered_file = template.render(manifest_properties, consumes: {})
          end

          it 'renders default values' do
            expect(@rendered_file).to include('log_format main escape=default')
          end

          context 'when json escaping for access log is configured' do
            let(:manifest_properties) { { 'cc' => { 'nginx_access_log_escaping' => 'json' } } }

            it 'renders escape=json' do
              expect(@rendered_file).to include('log_format main escape=json')
            end
          end
        end
      end

      context 'prom_scraper with all propeties set' do
        let(:manifest_properties) { { 'cc' => { 'prom_scraper_tls' => { 'public_cert' => 'a public cert', 'private_key' => 'a private key', 'ca_cert' => 'an authority'  } } } }

        it 'renders prom scraper server' do
          expect(@rendered_file).to include('include prom_scraper_mtls.conf')
        end
      end

      context 'prom_scraper with public_cert not set' do
        let(:manifest_properties) { { 'cc' => { 'prom_scraper_tls' => { 'private_key' => 'a private key', 'ca_cert' => 'an authority'  } } } }

        it 'does not render prom scraper server' do
          expect(@rendered_file).not_to include('include prom_scraper_mtls.conf')
        end
      end

      context 'prom_scraper with private_key not set' do
        let(:manifest_properties) { { 'cc' => { 'prom_scraper_tls' => { 'public_cert' => 'a public cert', 'ca_cert' => 'an authority'  } } } }

        it 'does not render prom scraper server' do
          expect(@rendered_file).not_to include('include prom_scraper_mtls.conf')
        end
      end

      context 'prom_scraper with ca_cert not set' do
        let(:manifest_properties) { { 'cc' => { 'prom_scraper_tls' => { 'public_cert' => 'a public cert', 'private_key' => 'a private key'  } } } }

        it 'does not render prom scraper server' do
          expect(@rendered_file).not_to include('include prom_scraper_mtls.conf')
        end
      end
    end
  end
end
