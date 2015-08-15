require 'puppet/indirector/hiera_hash'
require 'hiera/scope'

class Puppet::DataBinding::HieraHash < Puppet::Indirector::HieraHash
  desc "Retrieve data using HieraHash."
end

