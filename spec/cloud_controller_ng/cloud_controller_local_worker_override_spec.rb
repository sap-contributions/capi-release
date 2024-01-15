# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'

module Bosh
  module Template
    module Test
      describe 'cloud controller local worker override config template rendering' do
        let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
        let(:release) { ReleaseDir.new(release_path) }
        let(:job) { release.job('cloud_controller_ng') }

        describe 'config/cloud_controller_local_worker_override.yml' do
          let(:template) { job.template('config/cloud_controller_local_worker_override.yml') }
          let(:manifest_properties) { {} }

          it 'creates the cloud_controller_local_worker_override.yml config file' do
            expect do
              YAML.safe_load(template.render(manifest_properties, consumes: {}))
            end.not_to raise_error
          end

          it 'renders a default empty file' do
            template_hash = YAML.safe_load(template.render(manifest_properties, consumes: {}))
            expect(template_hash).to be_nil
          end

          context 'when db max connections per local worker value is set' do
            let(:manifest_properties) { { 'ccdb' => { 'max_connections_per_local_worker' => 10 } } }

            it 'renders the values into the file' do
              template_hash = YAML.safe_load(template.render(manifest_properties, consumes: {}))
              expect(template_hash['db']['max_connections']).to eq(10)
            end
          end
        end
      end
    end
  end
end
