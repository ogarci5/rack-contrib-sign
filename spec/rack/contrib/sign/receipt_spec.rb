
require 'spec_helper'

describe Rack::Contrib::Sign::Receipt do
  let (:receipt) { Rack::Contrib::Sign::Receipt.new }
  it { should respond_to(:api_key) }
  it { should respond_to(:api_key=) }
  it { should respond_to(:api_secret) }
  it { should respond_to(:api_secret=) }
  it { should respond_to(:body) }
  it { should respond_to(:body=) }
  it { should respond_to(:request_method) }
  it { should respond_to(:request_method=) }
  it { should respond_to(:uri) }
  it { should respond_to(:uri=) }
  it { should respond_to(:headers) }

  describe "#request_method" do
    it "upcases the method" do
      receipt.request_method = 'post'
      receipt.request_method.should eq('POST')
    end
  end

  describe "#headers" do
    it "defaults to an empty hash" do
      receipt.headers.should eq({})
    end

    it "keeps around my headers" do
      receipt.headers['A-a'] = 'foo'
      receipt.headers['B-b'] = 'bar'

      headers = receipt.headers

      headers.should eq({
        'A-a' => 'foo',
        'B-b' => 'bar'
      })
    end
  end

  describe "#preamble" do
    it "incorporates all the preamble elements in a string block" do
      receipt.api_key = 'abc'
      receipt.api_secret = '123'
      receipt.body = 'foo=bar'
      receipt.request_method = 'post'
      receipt.uri = 'http://example.com/123'

      returned = receipt.preamble

      r = "POST http://example.com/123\n"
      r << "abc\n"
      r << "123\n"
      r << "foo=bar\n"
      r << "--\n"

      returned.should eq(r)
    end
  end

  describe "#header_test" do
    it "sorts the headers alphabetically and lowercases them" do
      receipt.headers['B-b'] = 'bar'
      receipt.headers['A-a'] = 'foo'

      headers = receipt.header_text

      r = ""
      r << "a-a:foo\n"
      r << "b-b:bar\n"

      headers.should eq(r)
    end
  end

  describe "#to_s" do
    it "mushes to gether the preamble and headers" do
      receipt.stub(:preamble => "foo\n--\n")
      receipt.stub(:header_text=> "bar\n")

      returned = receipt.to_s

      receipt.should have_received(:preamble)
      receipt.should have_received(:header_text)
      returned.should eq("foo\n--\nbar\n")
    end
  end
end

