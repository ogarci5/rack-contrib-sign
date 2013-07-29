
module Rack
  module Contrib
    module Sign
      class Receipt
        attr_reader :request_method
        attr_reader :headers
        attr_accessor :api_key
        attr_accessor :api_secret
        attr_accessor :body
        attr_accessor :content_type
        attr_accessor :uri
        attr_accessor :host

        def initialize
          @headers = {}
        end

        def request_method= s
          @request_method = s.upcase
        end

        def body_md5
          Digest::MD5.hexdigest(body)
        end

        def body_length
          body.length
        end

        def to_s
          preamble + header_text
        end

        def preamble
          s = ""
          s << "%s\n" % request_method
          s << "%s\n" % host
          s << "%s\n" % uri
          s << "%s\n" % api_key
          s << "%s\n" % content_type
          s << "%s\n" % body_length
          s << "%s\n" % body_md5
          s
        end

        def header_text
          s = ""

          headers.sort_by { |k,v| k.downcase }.each do |header, value|
            s << "%s:%s\n" % [header.downcase, value]
          end

          s
        end
      end
    end
  end
end

