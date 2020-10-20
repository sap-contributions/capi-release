# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'yaml'
require 'json'

module Bosh::Template::Test
  describe 'bpm job template rendering' do

    def expect_default_debug_env_vars(results)
      expect(results[0]['env'].key?('DEBUG')).to eq(true)
      expect(results[0]['env'].key?('FOG_DEBUG')).to eq(true)
      expect(results[0]['env'].key?('ALIYUN_OSS_SDK_LOG_LEVEL')).to eq(false)
      expect(results[0]['env']['DEBUG']).to eq(true)
      expect(results[0]['env']['FOG_DEBUG']).to eq(true)
    end

    let(:release_path) { File.join(File.dirname(__FILE__), '../..') }
    let(:release) { ReleaseDir.new(release_path) }
    let(:job) { release.job('cloud_controller_ng') }

    let(:properties_debug_gcp) do
      {'cc' => {'log_fog_requests' => true, 'packages' => {'fog_connection' => { 'provider' => 'Google'} }}}
      end
    let(:properties_debug_azure) do
      {'cc' => {'log_fog_requests' => true, 'packages' => {'fog_connection' => { 'provider' => 'AzureRm'} }}}
      end
    let(:properties_debug_ali) do
      {'cc' => {'log_fog_requests' => true, 'packages' => {'fog_connection' => { 'provider' => 'aliyun'} }}}
    end
    let(:properties_debug_foo) do
      {'cc' => {'log_fog_requests' => true, 'packages' => {'fog_connection' => { 'provider' => 'foo'} }}}
    end
    let(:properties_without_debug) do
      {'cc' => {'log_fog_requests' => false, 'packages' => {'fog_connection' => { 'provider' => 'aliyun'} }}}
    end

    describe 'config/bpm.yml' do
      let(:template) { job.template('config/bpm.yml') }

      context 'when fog debug logging is enabled' do
        it 'sets the DEBUG env var for GCP' do
          template_hash = YAML.safe_load(template.render(properties_debug_gcp, consumes: { } ))

          results = template_hash['processes'].select { |p| p['name'].include?('cloud_controller_ng') }
          expect(results.length).to eq(1)
          expect_default_debug_env_vars(results)
        end

        it 'sets the FOG_DEBUG env var for Azure' do
          template_hash = YAML.safe_load(template.render(properties_debug_azure, consumes: { } ))

          results = template_hash['processes'].select { |p| p['name'].include?('cloud_controller_ng') }
          expect(results.length).to eq(1)
          expect(results[0]['env'].key?('DEBUG')).to eq(false)
          expect(results[0]['env'].key?('FOG_DEBUG')).to eq(true)
          expect(results[0]['env'].key?('ALIYUN_OSS_SDK_LOG_LEVEL')).to eq(false)
          expect(results[0]['env']['FOG_DEBUG']).to eq(true)
        end

        it 'sets the ALIYUN_OSS_SDK_LOG_LEVEL env var for Ali' do
          template_hash = YAML.safe_load(template.render(properties_debug_ali, consumes: { } ))

          results = template_hash['processes'].select { |p| p['name'].include?('cloud_controller_ng') }
          expect(results.length).to eq(1)
          expect(results[0]['env'].key?('DEBUG')).to eq(true)
          expect(results[0]['env'].key?('FOG_DEBUG')).to eq(true)
          expect(results[0]['env'].key?('ALIYUN_OSS_SDK_LOG_LEVEL')).to eq(true)
          expect(results[0]['env']['ALIYUN_OSS_SDK_LOG_LEVEL']).to eq('debug')
          expect(results[0]['env']['DEBUG']).to eq(true)
          expect(results[0]['env']['FOG_DEBUG']).to eq(true)
        end

        it 'sets not any debug env var for Foo' do
          template_hash = YAML.safe_load(template.render(properties_debug_foo, consumes: { } ))

          results = template_hash['processes'].select { |p| p['name'].include?('cloud_controller_ng') }
          expect(results.length).to eq(1)
          expect_default_debug_env_vars(results)
        end
      end

      context 'when fog debug logging is disabled' do
        it 'sets not any debug env var' do
          template_hash = YAML.safe_load(template.render(properties_without_debug, consumes: { } ))

          results = template_hash['processes'].select { |p| p['name'].include?('cloud_controller_ng') }
          expect(results.length).to eq(1)
          expect(results[0]['env'].key?('DEBUG')).to eq(false )
          expect(results[0]['env'].key?('FOG_DEBUG')).to eq(false)
          expect(results[0]['env'].key?('ALIYUN_OSS_SDK_LOG_LEVEL')).to eq(false)
        end
      end
    end
  end
end
