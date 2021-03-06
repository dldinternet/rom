require 'rom/mapper_registry'

module ROM
  # @api private
  class ReaderBuilder
    DEFAULT_OPTIONS = { inherit_header: true }.freeze

    attr_reader :relations, :readers

    # @api private
    def initialize(relations)
      @relations = relations
      @readers = {}
    end

    # @api private
    def call(name, input_options = {}, &block)
      with_options(input_options) do |options|
        parent = relations[options.fetch(:parent) { name }]

        builder = MapperBuilder.new(name, parent, options)
        builder.instance_exec(&block) if block
        mapper = builder.call

        mappers =
          if options[:parent]
            readers.fetch(parent.name).mappers
          else
            MapperRegistry.new
          end

        mappers[name] = mapper

        unless options[:parent]
          readers[name] = Reader.build(
            name, parent, mappers, parent.class.relation_methods
          )
        end
      end
    end

    private

    def with_options(options)
      yield(DEFAULT_OPTIONS.merge(options))
    end
  end
end
