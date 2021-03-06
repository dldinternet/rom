module ROM
  # @api private
  class ModelBuilder
    attr_reader :options, :const_name, :namespace, :klass

    def self.[](type)
      case type
      when :poro then PORO
      else
        raise ArgumentError, "#{type.inspect} is not a supported model type"
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(options = {})
      @options = options

      name = options[:name]
      if name
        parts = name.split('::')

        @const_name = parts.pop

        @namespace =
          if parts.any?
            Inflecto.constantize(parts.join('::'))
          else
            Object
          end
      end
    end

    def define_const
      namespace.const_set(const_name, klass)
    end

    def call(header)
      define_class(header)
      define_const if const_name
      @klass
    end

    class PORO < ModelBuilder
      def define_class(header)
        @klass = Class.new

        attrs = header.keys

        @klass.send(:attr_reader, *attrs)

        @klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def initialize(params)
            #{attrs.map { |name| "@#{name} = params[:#{name}]" }.join("\n")}
          end
        RUBY

        self
      end
    end
  end
end
