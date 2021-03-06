require 'rom/model_builder'

module ROM
  # @api private
  class MapperBuilder
    class AttributeDSL
      attr_reader :attributes, :model_class, :model_builder

      def initialize
        @attributes = []
      end

      def header
        Header.coerce(attributes)
      end

      def model(options = nil)
        if options.is_a?(Class)
          @model_class = options
        elsif options
          type = options.fetch(:type) { :poro }
          @model_builder = ModelBuilder[type].new(options)
        end

        if options
          self
        else
          model_class || (model_builder && model_builder.call(header))
        end
      end

      def attribute(name, options = {})
        attributes << [name, options]
      end
    end

    attr_reader :name, :root, :prefix,
      :model_builder, :model_class, :attributes

    def initialize(name, root, options = {})
      @name = name
      @root = root
      @prefix = options[:prefix]

      @attributes =
        if options[:inherit_header]
          root.header.map { |attr| [prefix ? :"#{prefix}_#{attr}" : attr] }
        else
          []
        end
    end

    def model(options)
      if options.is_a?(Class)
        @model_class = options
      else
        type = options.fetch(:type) { :poro }
        @model_builder = ModelBuilder[type].new(options)
      end

      self
    end

    def attribute(name, options = {})
      add_attribute(name, options) do
        options[:from] = :"#{prefix}_#{name}" if prefix
        attributes << [name, options]
      end
    end

    def exclude(name)
      attributes.delete([name])
    end

    def embedded(name, options = {}, &block)
      add_attribute(name, options) do
        dsl = AttributeDSL.new
        dsl.instance_exec(&block)

        attributes << [
          name,
          { header: dsl.header, type: Array, model: dsl.model }.merge(options)
        ]
      end
    end

    def group(options, &block)
      attribute_dsl(options, Array, &block)
    end

    def wrap(options, &block)
      attribute_dsl(options, Hash, &block)
    end

    def call
      header = Header.coerce(attributes)

      @model_class = model_builder.call(header) if model_builder

      Mapper.build(header, model_class)
    end

    private

    def add_attribute(name, options = {})
      exclude(name)
      exclude(options[:from])
      yield
    end

    def attribute_dsl(args, type, &block)
      if block
        name = args

        dsl = AttributeDSL.new
        dsl.instance_exec(&block)
        attributes << [name, header: dsl.header, type: type,
                       model: dsl.model, transform: true]
      else
        args.each do |name, header|
          attributes << [name, header: header.zip, type: type, transform: true]
        end
      end
    end
  end
end
