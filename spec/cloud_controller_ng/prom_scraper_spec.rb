# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'

module Bosh
  module Template
    module Test
      describe 'prom_scraper config template rendering' do
        let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
        let(:release) { ReleaseDir.new(release_path) }
        let(:job) { release.job('cloud_controller_ng') }

        describe 'prom_scraper_config.yml' do
          let(:template) { job.template('config/prom_scraper_config.yml') }
          let(:manifest_properties) { {} }

          before do
            @rendered_file = template.render(manifest_properties, consumes: {})
          end

          it 'renders default values' do
            expect(@rendered_file).to include('port: 9025')
          end

          context 'when prom_scraper is disabled' do
            let(:manifest_properties) { { 'cc' => { 'prom_scraper' => { 'disabled' => true } } } }

            it 'renders an empty file' do
              expect(@rendered_file).not_to include('port: 9025')
            end
          end
        end
      end
    end
  end
end
