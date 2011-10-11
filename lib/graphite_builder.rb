require 'uri'
require 'cgi'

module Graphite

  # Graphite::Builder.new(:hostname => 'foo') do
  #   base 'http://my_graphite.host/render/'
  #   width 800
  #   height 200
  #   areaMode :stacked
  #   from '-2hours'
  #   base_url 'http://localhost:8080/render/'
  #   target(legend(color(sumSeries("#{data :hostname}.cpu-*.cpu-steal.value"), :red), 'Steal'))
  #   target(legend(color(sumSeries("#{data :hostname}.cpu-*.cpu-steal.value"), :green), 'Idle'))
  # end.render
  class Builder

    class NoTargetsDefined < RuntimeError; end
    class UnknownMethodFormat < RuntimeError; end

    def initialize(opts=nil, &block)
      @args = {}
      @targets = []
      data opts
      @args[:base_url] = @data.delete(:base_url) if @data[:base_url]
      if block
        self.instance_eval(&block)
      end
    end

    def target(value)
      @targets << value
    end

    def data(opts=nil)
      case opts
      when Hash, Array
        @data = opts
      when String, Symbol, Fixnum
        @data[opts]
      when NilClass
        @data
      else
        raise RuntimeError.new("Unknown options: #{opts}")
      end
    end

    def sumSeries(*args)
      array_argument_wrapper('sumSeries', args)
    end

    def asPercent(is, of)
      array_argument_wrapper('asPercent', is, of)
    end

    def secondYAxis(arg)
      single_argument_wrapper('secondYAxis',arg)
    end

    def stacked(arg)
      single_argument_wrapper('stacked',arg)
    end

    def method_missing(meth,*args,&block)
      if args.length == 2
        if meth == :legend
          meth = :alias
        end
        quoted_array_argument_wrapper(meth, args)
      elsif args.length == 1
        @args[meth.to_sym] = args.first
      else
        raise ::Graphite::Builder::UnknownMethodFormat.new("#{meth}(#{args.join(',')})")
      end
    end

    def render
      raise ::Graphite::Builder::NoTargetsDefined.new if @targets.empty?
      '<img src="' <<
      @args.delete(:base_url) << '?' <<
        (@args.map do |k ,v|
          if v.is_a?(Array)
            v.map { |item| url_param(k, item) }.join("&")
          else
            url_param(k, v)
          end
        end + @targets.map {|target| "target=#{target}" }).join('&') << '"/>'
    end

    private

    def single_argument_wrapper(meth, arg)
      "#{meth}(#{arg})"
    end

    def array_argument_wrapper(meth, *args)
      "#{meth}(#{args.join(",")})"
    end

    def quoted_array_argument_wrapper(meth, *args)
      args = args[0] if args[0].is_a? Array
      "#{meth}(#{args.shift},#{args.map { |a| "'#{CGI::escape(a.to_s)}'"}.join(',')})"
    end

    def url_param(param, value)
      "#{URI.escape(param.to_s)}=#{CGI::escape(value.to_s)}"
    end

  end
end
