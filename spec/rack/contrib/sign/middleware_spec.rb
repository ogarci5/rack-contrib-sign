require 'spec_helper'

describe Rack::Contrib::Sign::Middleware do
  let (:app) do
    app = double()
    app.stub(:call => 'Hello, world!')

    app
  end
  let (:log_string) { StringIO.new }
  let (:logger) do
    logger = Logger.new(log_string, Logger::DEBUG)
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity} - #{msg}\n"
    end

    logger
  end
  let (:ware) { Rack::Contrib::Sign::Middleware.new(
    app,
    logger: logger,
    realm: "foo-bar",
    prefix: "HI-"
  )}

  describe "#build_receipt" do
    it "sets various options" do
      env = {
        'REQUEST_METHOD' => 'POST',
        'REQUEST_URI' => 'foo/bar',
        'HTTP_AUTHORIZATION' => 'foo-bar 123:mysignature',
        'HTTP_HI_FOOO' => 'YIPEE',
        'rack.input' => StringIO.new('foo=bar')
      }

      receipt = ware.build_receipt env

      receipt.uri.should eq('foo/bar')
      receipt.request_method.should eq('POST')
      receipt.body.should eq('foo=bar')
      receipt.headers.should eq({
        'HI-FOOO' => 'YIPEE',
      })

    end
  end

  describe "#extract_body" do
    it "returns the body of a request from the environment" do
      env = {
        'rack.input' => StringIO.new('fooz=baz')
      }

      ware.extract_body(env).should eq('fooz=baz')
    end

    it "rewinds the input after reading" do
      str = StringIO.new('fooz=baz')
      env = {
        'rack.input' => str
      }

      str.pos.should eq(0)
    end
  end


  describe "#extract_headers" do
    it "returns headers prefixed with HI-" do
      headers = {
        'HTTP_HI_FOO' => ':/',
        'HTTP_BYE_FOO' => ':(',
        'HTTP_HI_oentuheou' => ':)'
      }

      found_headers = ware.extract_headers(headers)

      expected_headers = {
        'HI-FOO' => ':/',
        'HI-oentuheou' => ':)'
      }
      found_headers.should eq(expected_headers)
    end
  end

  describe "#extract_credentials" do
    it "returns false when nil is provided" do
      header = nil

      ware.extract_credentials(header).should eq(false)
    end

    it "returns false when the header is garbled" do
      header = "LOL WHAT I DON'T EVEN"

      ware.extract_credentials(header).should eq(false)
    end

    it "returns my key and signature when a formatted string is provided" do
      header = 'foo-bar mykey:signature'

      ware.extract_credentials(header).should eq(key: 'mykey', signature: 'signature')
    end

    it "returns false if the realm fails to match" do
      header = 'foo-bar-baz mykey:signature'

      ware.extract_credentials(header).should eq(false)
    end

  end

  describe "#call" do
    context "I have no other tests" do
      it "abandons ship if there is no authorization header" do
        env = {}

        returned = ware.call(env)

        returned.should eq([401, {}, []])
        log_string.string.should eq("INFO - Denied: Authorization header not present or invalid.\n")
      end

      it "401s when I don't sign it right" do
        env = {
          'HTTP_AUTHORIZATION' => 'foo-bar abc:YABBA DABBA DOOO',
          'REQUEST_METHOD' => 'POST',
          'REQUEST_URI' => 'http://foo/bar/baz',
          'rack.input' => StringIO.new('foo=bar'),
        }

        returned = ware.call(env)

        returned.should eq([401, {}, []])
      end
      it "works when I sign it right" do
        env = {
          'HTTP_AUTHORIZATION' => 'foo-bar 123:0d501b6934dc0ec5f1452947a7afd108e41c91af',
          'REQUEST_METHOD' => 'POST',
          'REQUEST_URI' => 'http://foo/bar/baz',
          'rack.input' => StringIO.new('foo=bar'),
          'HTTP_HI_FOOOO' => 'aoenuoneuh',
          'HTTP_BYE_FOOO' => 'oeucorgcgc'
        }

        returned = ware.call(env)

        log_string.string.should eq('')
        app.should have_received(:call).once.with(env)
        returned.should eq('Hello, world!')
      end
    end
  end
end

