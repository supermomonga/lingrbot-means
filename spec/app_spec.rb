# encoding: utf-8

ENV['RACK_ENV'] = 'test'

$:.unshift File.dirname(__FILE__) + '/../'
require 'app.rb'
require 'spec_helper'
require 'json'
require 'rack/test'

describe 'The Semantics=san' do
  include Rack::Test::Methods

  def app
    Bot
  end

  it 'web' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'ping' do
    post '/', create_message_json('ping')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('pong')
  end

  it 'seiga' do
    post '/', create_message_json('http://seiga.nicovideo.jp/seiga/im5479269')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('http://lohas.nicoseiga.jp/thumb/5479269i#.png')
  end
end
