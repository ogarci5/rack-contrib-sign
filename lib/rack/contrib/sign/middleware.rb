
module Rack
  module Contrib
    module Sign
      class Middleware
        def initialize app, opts

          @app = app
          @logger = opts[:logger]
          @realm = opts[:realm]
          @header_prefix = (opts[:prefix] || "").gsub(/-/, '_').downcase
        end

        def call env

          unless env['HTTP_AUTHORIZATION']
            @logger.info "Denied: Authorization header not present."
            return [401, {}, []]
          end

          api_key = '123'
          api_secret = 'abc'

          receipt = Rack::Contrib::Sign::Receipt.new
          receipt.request_method = env['REQUEST_METHOD']
          receipt.uri = env['REQUEST_URI']
          receipt.api_key = api_key
          receipt.api_secret = api_secret
          receipt.body = env['rack.input'].read

          env['rack.input'].rewind

          env.sort_by { |k,v| k.to_s.downcase }.each do |key,val|
            next unless key =~ /^http_#{@header_prefix}/i
            header = key.sub(/^http_/i, '').gsub(/_/, '-')
            receipt.headers[header] = val
          end

          sign = receipt.to_s

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
end
