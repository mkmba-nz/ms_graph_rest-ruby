require 'camel_snake_struct'

module MsGraphRest
  class Calendars
    class Response < CamelSnakeStruct
      include Enumerable

      def initialize(data)
        @data = data
        super(data)
      end

      def each
        value.each { |val| yield(val) }
      end

      def next_get_query
        return nil unless odata_next_link

        uri = URI.parse(odata_next_link)
        params = CGI.parse(uri.query)
        { select: params["$select"]&.first,
          skiptoken: params["$skiptoken"]&.first,
          filter: params["$filter"]&.first }.compact
      end

      def size
        value.size
      end
    end
    Response.example('value' => [], "@odata.context" => "", "@odata.nextLink" => "")

    attr_reader :client, :path, :query

    def initialize(path, client:, query: {})
      @path = "#{path.to_str}".gsub('//', '/')
      @path[0] = '' if @path.start_with?('/')
      @client = client
      @query = query
    end

    def get(select: nil, filter: nil, skiptoken: nil)
      Response.new(client.get("#{path}/calendars",
                              query.merge({ '$select' => select,
                                            '$filter' => filter,
                                            '$skiptoken' => skiptoken }.compact)))
    end

    def filter(val)
      new_with_query(query.merge('$filter' => val))
    end

    def select(val)
      val = val.map(&:to_s).map { |v| v.camelize(:lower) }.join(',') if val.is_a?(Array)
      new_with_query(query.merge('$select' => val))
    end

    private

    def new_with_query(query)
      self.class.new(path, client: client, query: query)
    end
  end
end
