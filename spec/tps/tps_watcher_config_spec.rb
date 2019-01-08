# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

# rubocop:disable Metrics/BlockLength
module Bosh::Template::Test
  describe 'tps job template rendering' do
    let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
    let(:release) { ReleaseDir.new(release_path) }
    let(:job) { release.job('tps') }

    describe 'config/tps_watcher_config.json' do
      let(:links) { [] }
      let(:template) { job.template('config/tps_watcher_config.json') }

      describe 'log time format' do
        it 'defaults the log timestamp format to rfc3339' do
          rendered_template = template.render({}, consumes: links)
          parsed_template = JSON.parse(rendered_template)

          expect(parsed_template['lager_config']['time_format']).to eq('rfc3339')
        end

        context 'when the specified format is unix-epoch' do
          let(:manifest_overrides) do
            {
              'capi' => {
                'tps' => {
                  'logging' => {
                    'format' => {
                      'timestamp' => 'unix-epoch'
                    }
                  }
                }
              }
            }
          end

          it 'sets the log timestamp format to unix-epoch' do
            rendered_template = template.render(manifest_overrides, consumes: links)
            parsed_template = JSON.parse(rendered_template)

            expect(parsed_template['lager_config']['time_format']).to eq('unix-epoch')
          end
        end

        context 'when the specified format is something unknown' do
          let(:manifest_overrides) do
            {
              'capi' => {
                'tps' => {
                  'logging' => {
                    'format' => {
                      'timestamp' => 'bogus-8601'
                    }
                  }
                }
              }
            }
          end

          it 'raises an error' do
            expect {
              template.render(manifest_overrides, consumes: links)
            }.to raise_error(RuntimeError, "capi.tps.logging.format.timestamp should be one of: 'unix-epoch' or 'rfc3339'")
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
