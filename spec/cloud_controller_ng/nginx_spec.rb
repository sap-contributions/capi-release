# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'

module Bosh::Template::Test
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

      context 'json escaping for access log is configured' do
        let(:manifest_properties) { { 'cc' => { 'nginx_access_log_escaping' => 'json' } } }

        it 'renders escape=json' do
          expect(@rendered_file).to include('log_format main escape=json')
        end
      end
    end
  end
end
