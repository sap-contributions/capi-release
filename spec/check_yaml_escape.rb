require 'rspec'
require 'bosh/template/test'
#require 'yaml'
#require 'json'
require 'find'

module Bosh::Template::Test
  describe 'verify yaml-escape is defined' do
   it 'checks yaml-escape' do
    jobs_dir = File.expand_path('../jobs', File.dirname(__FILE__))
    puts jobs_dir

    files = []

     Find.find(jobs_dir) do |path|
       if path['.yml.erb']
         text = IO.read(path)
         if text['yaml_escape('] && !text['def yaml_escape']
           files << path
           # expect(text['def yaml_escape']).not_to be_nil, "no yaml_escape defined in #{path}"
         end
       end
     end
     expect(files).to be_empty()
   end
  end
end
