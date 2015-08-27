require 'spec_helper'
require 'shared_behaviours/hiera_indirections'
require 'puppet_spec/files'
require 'puppet/indirector/data_binding/hiera_hash'

describe Puppet::DataBinding::HieraHash do
  it "should have documentation" do
    expect(Puppet::DataBinding::HieraHash.doc).not_to be_nil
  end

  it "should be registered with the data_binding indirection" do
    indirection = Puppet::Indirector::Indirection.instance(:data_binding)
    expect(Puppet::DataBinding::HieraHash.indirection).to equal(indirection)
  end

  it "should have its name set to :hierahash" do
    expect(Puppet::DataBinding::HieraHash.name).to eq(:hiera_hash)
  end

  it_should_behave_like "Hiera indirection", Puppet::DataBinding::HieraHash, my_fixture_dir
end
