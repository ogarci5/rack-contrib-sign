
module Rack
  module Contrib
    module Sign
      class Receipt
        attr_reader :request_method
        attr_reader :headers
        attr_accessor :api_key
        attr_accessor :api_secret
        attr_accessor :body
        attr_accessor :uri

        def initialize
          @headers = {}
        end

        def request_method= s
          @request_method = s.upcase
        end

        def to_s
          preamble + header_text
        end

        def preamble
          s = ""
          s << "%s %s\n" % [request_method, uri]
          s << "%s\n" % api_key
          s << "%s\n" % api_secret
          s << "%s\n" % body
          s << "--\n"
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

