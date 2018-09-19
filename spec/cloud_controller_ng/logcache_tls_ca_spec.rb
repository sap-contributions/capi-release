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

    describe 'config/certs/logcache_tls_ca.crt' do
      let(:links) { [] }
      let(:log_cache_link) { Link.new(name: 'log-cache', properties: { 'tls' => { 'ca_cert' => 'i-am-a-ca-cert' } }) }
      let(:template) { job.template('config/certs/logcache_tls_ca.crt') }

      context 'when the log-cache link is present' do
        let(:links) { [log_cache_link] }

        it 'renders the contents of tls.ca_cert in the template' do
          rendered_template = template.render({}, consumes: links)

          expect(rendered_template).to eq("i-am-a-ca-cert\n")
        end
      end

      context 'when the log-cache link is not present' do
        it 'renders the contents of tls.ca_cert in the template' do
          rendered_template = template.render({}, consumes: links)

          expect(rendered_template).to eq("\n")
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
