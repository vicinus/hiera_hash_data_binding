require 'puppet/indirector/terminus'
require 'hiera/scope'

class Puppet::Indirector::HieraHash < Puppet::Indirector::Terminus
  attr_reader :class_name
  attr_reader :class_params

  def initialize(*args)
    if ! Puppet.features.hiera?
      raise "HieraHash terminus not supported without hiera library"
    end
    @class_name = nil
    @class_params = {}
    super
  end

  if defined?(::Psych::SyntaxError)
    DataBindingExceptions = [::StandardError, ::Psych::SyntaxError]
  else
    DataBindingExceptions = [::StandardError]
  end

  def find(request)
    request_class_name, *b, request_param = request.key.rpartition('::')
    if @class_name.nil? or @class_name != request_class_name
      if ! @class_params.empty?
        Puppet.warning "Unused loaded hiera parameters for class #{@class_name}: '#{@class_params.keys.join("' '")}'."
      end
      @class_params = hiera.lookup(request_class_name, {}, Hiera::Scope.new(request.options[:variables]), nil, :hash)
      @class_name = request_class_name
    end
    @class_params.delete(request_param)
  rescue *DataBindingExceptions => detail
    raise Puppet::DataBinding::LookupError.new(detail.message, detail)
  end

  private

  def self.hiera_config
    hiera_config = Puppet.settings[:hiera_config]
    config = {}

    if Puppet::FileSystem.exist?(hiera_config)
      config = Hiera::Config.load(hiera_config)
    else
      Puppet.warning "Config file #{hiera_config} not found, using Hiera defaults"
    end

    config[:logger] = 'puppet'
    config
  end

  def self.hiera
    @hiera ||= Hiera.new(:config => hiera_config)
  end

  def hiera
    self.class.hiera
  end
end

