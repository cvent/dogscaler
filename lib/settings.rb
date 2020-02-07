require 'yaml'
module Settings
    # again - it's a singleton, thus implemented as a self-extended module
    extend self

    @_settings = {}
    attr_reader :_settings

    # This is the main point of entry - we call Settings.load! and provide
    # a name of the file to read as it's argument.
    def load!(filename)
        newsets = YAML::load_file(filename)
        deep_merge!(@_settings, newsets)
    end

    # Deep merging of hashes
    # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
    def deep_merge!(target, data)
        merger = proc{|key, v1, v2|
          Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        target.merge! data, &merger
    end

    def method_missing(name, *args, &block)
        return @_settings[name.to_s] ||
        fail(NoMethodError, "Unknown configuration root #{name}", caller)
    end

end

if ENV['HOME'].nil?
  require 'etc'
  ENV['HOME'] = Etc.getpwuid.dir
end

app_name = "dogscaler"
overrides = File.expand_path("~/.#{app_name}.yaml")
Settings.load!(overrides) if File.exists? overrides
