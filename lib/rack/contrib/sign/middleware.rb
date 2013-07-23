
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
          creds = extract_credentials env['HTTP_AUTHORIZATION']
          unless creds
            @logger.info "Denied: Authorization header not present or invalid."
            return [401, {}, []]
          end

          receipt = build_receipt env
          receipt.api_key = creds[:key]
          receipt.api_secret = get_secret creds[:key]

          sign = receipt.to_s

          digest = OpenSSL::Digest::Digest.new('sha1')
          validation = OpenSSL::HMAC.hexdigest(digest, receipt.api_secret, sign)

          unless validation == creds[:signature]
            @logger.error "Denied: Authorization signature does not match"
            @logger.info "Denied: EXPECTED: %s GOT: %s" % [
              validation,
              creds[:signature]
            ]
            @logger.debug "Generated signing data:"
            @logger.debug sign
            return [401, {}, []]
          end

          @app.call env
        end

        # Extract environmental data into a Receipt
        def build_receipt env
          receipt = Rack::Contrib::Sign::Receipt.new
          receipt.uri = env['REQUEST_URI']
          receipt.request_method = env['REQUEST_METHOD']
          receipt.body = extract_body env

          extract_headers(env).each { |h,v| receipt.headers[h] = v }

          receipt
        end

        # Extract the body from the environment, ensuring to rewind
        # the input back to zero, so future access gets the arguments.
        def extract_body env
          env['rack.input'].read
        ensure
          env['rack.input'].rewind
        end

        # Extract all the headers with our Prefix from the ENV
        # and return the hash
        def extract_headers env
          headers = {}

          env.sort_by { |k,v| k.to_s.downcase }.each do |key,val|
            next unless key =~ /^http_#{@header_prefix}/i
            header = key.sub(/^http_/i, '').gsub(/_/, '-')
            headers[header] = val
          end

          headers
        end

        # Pass in the Authorization header, and get back the key
        # and signature.
        def extract_credentials auth_header
          return false if auth_header.nil?

          pattern = /^(?<realm>.*) (?<api_key>.*):(?<signature>.*)$/
          matches = auth_header.match(pattern)

          return false if matches.nil?
          return false unless matches[:realm] == @realm

          {
            key: matches[:api_key],
            signature: matches[:signature]
          }
        end

        def get_secret api_key
          return 'abc'
        end
      end
    end
  end
end
