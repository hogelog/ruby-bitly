require "uri"
require "net/http"

Net::HTTP.version_1_2

module Bitly
  VERSION = "0.0.1"
  @@http = Net::HTTP
  @@proxy_addr = nil
  @@proxy_port = nil

  class ServerError < ::StandardError
  end
  class ArgumentError < ::ArgumentError
  end
  class << self
    def proxy(addr, port)
      @@http = Net::HTTP.Proxy(addr, port)
    end
    def short(uri)
      encode = URI.encode(uri)
      @@http.start("bit.ly", 80){|http|
        res = http.get("/api?url=#{encode}")
        body = res.body
        if /^http:\/\// =~ body
          body
        else
          raise Bitly::ServerError.new(body)
        end
      }
    end
    def expand(uri)
      parse = URI.parse(uri)
      host, port, path = parse.host, parse.port, parse.path
      if host != "bit.ly"
        raise Bitly::ArgumentError.new("#{uri} is not bit.ly URI")
      end
      @@http.start(host, port){|http|
        res = http.get(path)
        body = res.body
        if /<a href="([^"]+)">/i =~ body
          $1
        else
          raise Bitly::ServerError.new(body)
        end
      }
    end
  end
end
