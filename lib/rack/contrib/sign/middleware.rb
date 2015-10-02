
module Rack
  module Contrib
    module Sign
      class Middleware
        def initialize app, opts

          @app = app
          @logger = opts[:logger]
          @realm = opts[:realm]
          @credentials = opts[:credentials] || {}
          @header_prefix = (opts[:prefix] || "").gsub(/-/, '_').downcase
        end

        def call env
          @logger.debug env.inspect
          creds = extract_credentials env['HTTP_AUTHORIZATION']
          unless creds
            @logger.info "Denied: Authorization header not present or invalid."
            return [401, {}, []]
          end

          receipt = build_receipt env, creds
          unless receipt.api_secret
            @logger.info "Denied: API key not recognized."
            return [401, {}, []]
          end

          sign = receipt.to_s
          @logger.debug sign

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
        def build_receipt env, credentials
          req = Rack::Request.new(env)
          receipt = Rack::Contrib::Sign::Receipt.new

          port = ''
          unless (
            (req.scheme == 'http' && req.port.to_s == '80') ||
            (req.scheme == 'https' && req.port.to_s == '443'))
            port = ':' + req.port.to_s
          end

          receipt.host = req.scheme + '://' + req.host + port
          receipt.uri = env['REQUEST_URI']
          receipt.request_method = env['REQUEST_METHOD']
          receipt.body = extract_body env
          receipt.content_type = env['CONTENT_TYPE'] || ''

          extract_headers(env).each { |h,v| receipt.headers[h] = v }

          receipt.api_key = credentials[:key]
          receipt.api_secret = get_secret(credentials[:key])

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
          return false unless @credentials.has_key? api_key

          return @credentials.fetch(api_key)
        end
      end
    end
  end
end
