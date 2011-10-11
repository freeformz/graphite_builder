require 'uri'
require 'cgi'

module Graphite

  # Encapsulates a small DSL for enabling the cut-n-paste of data from the graphite UI and interpolating/
  # modifying them for inclusion in a server side template
  class Builder

    # Raised when no targets are defined for a graph and #render is called
    class NoTargetsDefined < RuntimeError; end

    # Raised when we don't understand the function signature
    # i.e. the user did something wrong or we need to implement the
    # specific function signature
    class UnknownFunctionSignature < RuntimeError; end

    # args are optional arguments for constructing the url
    # opts are data to retrieve
    def initialize(args={}, &block)
      @args = args
      @targets = []
      if block
        self.instance_eval(&block)
      end
    end

    def target(value)
      @targets << value
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
        raise ::Graphite::Builder::UnknownFunctionSignature.new("#{meth}(#{args.join(',')})")
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
