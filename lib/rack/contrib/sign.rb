require "rack/contrib/sign/version"

module Rack
  module Contrib
    class Sign
      def initialize app, logger, realm, prefix
        @app = app
        @logger = logger
        @realm = realm
        @header_prefix = prefix.gsub(/-/, '_').downcase
      end

      def call env

        unless env['HTTP_AUTHORIZATION']
          @logger.error "Denied: Authorization header not present."
          return [401, {}, []]
        end

        api_key = '123'
        api_secret = 'abc'

        sign = "#{env['REQUEST_METHOD'].upcase} #{env['REQUEST_URI']}\n"
        sign << "#{api_key}\n"
        sign << "#{api_secret}\n"
        sign << env['rack.input'].read + "\n"
        sign << "--\n"

        env['rack.input'].rewind

        env.sort_by { |k,v| k.to_s.downcase }.each do |key,val|
          header = key.downcase
          next unless header =~ /^http_#{@header_prefix}/
          header = header.sub(/^http_/, '').gsub(/_/, '-')
          sign << "#{header}:#{val}\n"
        end

        digest = OpenSSL::Digest::Digest.new('sha1')
        validation = OpenSSL::HMAC.hexdigest(digest, api_secret, sign)

        expected_auth_header = "#{@realm} #{api_key}:#{validation}"

        unless env['HTTP_AUTHORIZATION'] == expected_auth_header
          @logger.error "Denied: Authorization signature does not match"
          @logger.info sprintf(
            "Denied: EXPECTED: %s GOT: %s",
            expected_auth_header,
            env['HTTP_AUTHORIZATION']
          )
          @logger.debug "Generated signing data:"
          @logger.debug sign
          return [401, {}, []]
        end

        @app.call env
      end
    end
  end
end

