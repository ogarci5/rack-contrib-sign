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
  let (:ware) { Rack::Contrib::Sign::Middleware.new(app, logger, "foo-bar", "HI-") }

  describe "#call" do
    context "I have no other tests" do
      it "abandons ship if there is no authorization header" do
        env = {}

        returned = ware.call(env)

        returned.should eq([401, {}, []])
        log_string.string.should eq("INFO - Denied: Authorization header not present.\n")
      end

      it "401s when I don't sign it right" do
        env = {
          'HTTP_AUTHORIZATION' => 'foo-bar YABBA DABBA DOOO',
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

