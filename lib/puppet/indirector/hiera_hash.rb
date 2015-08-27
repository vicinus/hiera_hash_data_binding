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
    v4 = Puppet.version.match('^4\.')
    if ! request.key.include? '::'
      if v4
        not_found = Object.new
        options = request.options
        return hiera.lookup(request.key, not_found, Hiera::Scope.new(options[:variables]), nil, convert_merge(options[:merge]))
      else
        return hiera.lookup(request.key, nil, Hiera::Scope.new(request.options[:variables]), nil, nil)
      end
    end
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

  # Converts a lookup 'merge' parameter argument into a Hiera 'resolution_type' argument.
  #
  # @param merge [String,Hash,nil] The lookup 'merge' argument
  # @return [Symbol,Hash,nil] The Hiera 'resolution_type'
  def convert_merge(merge)
    case merge
    when nil
      # Nil is OK. Defaults to Hiera :priority
      nil
    when 'unique'
      # Equivalent to Hiera :array
      :array
    when 'hash'
      # Equivalent to Hiera :hash with default :native merge behavior. A Hash must be passed here
      # to override possible Hiera deep merge config settings.
      { :behavior => :native }
    when 'deep'
      # Equivalent to Hiera :hash with :deeper merge behavior.
      { :behavior => :deeper }
    when Hash
      strategy = merge['strategy']
      if strategy == 'deep'
        result = { :behavior => :deeper }
        # Remaining entries must have symbolic keys
        merge.each_pair { |k,v| result[k.to_sym] = v unless k == 'strategy' }
        result
      else
        convert_merge(strategy)
      end
    else
      raise Puppet::DataBinding::LookupError, "Unrecognized value for request 'merge' parameter: '#{merge}'"
    end
  end

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

