# frozen_string_literal: true

require 'rspec'
require 'bosh/template/test'
require 'find'

module Bosh
  module Template
    module Test
      describe 'verify yaml-escape is defined' do
        it 'checks yaml-escape' do
          jobs_dir = File.expand_path('../jobs', File.dirname(__FILE__))

          Find.find(jobs_dir) do |path|
            next unless path['.yml.erb']

            text = File.read(path)
            expect(text['def yaml_escape']).not_to be_nil, "no yaml_escape defined in #{path}" if text['yaml_escape('] && !text['def yaml_escape']
          end
        end
      end
    end
  end
end
