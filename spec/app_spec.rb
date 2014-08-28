# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/../'
require 'spec_helper'
require 'app.rb'

describe Bot do
  it 'success anytime' do
    expect(:hi).to eq :hi
  end
end
