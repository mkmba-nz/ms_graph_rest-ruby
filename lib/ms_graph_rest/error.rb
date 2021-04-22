module MsGraphRest
  def self.wrap_request_error(faraday_error)
    case faraday_error
    when Faraday::ResourceNotFound
      ResourceNotFound.new(faraday_error)
    when Faraday::BadRequestError
      BadRequestErrorCreator.error(faraday_error)
    when Faraday::ServerError
      ServerErrorCreator.error(faraday_error)
    else
      faraday_error
    end
  end

  class Error < StandardError
  end

  class ResourceNotFound < Error
  end

  class AuthenticationError < Error
  end

  class BadRequestErrorCreator
    def self.error(ms_error)
      ms_error_code = JSON.parse(ms_error.response[:body] || '{}').dig("error", "code")

      return AuthenticationError.new(ms_error) if ms_error_code == 'AuthenticationError'

      return ms_error
    end
  end

  class UnableToResolveUserId < Error
  end

  class ServerErrorCreator
    def self.error(faraday_error)
      parsed_error = JSON.parse(faraday_error.response[:body] || '{}')
      message = parsed_error.dig("error", "message")

      return UnableToResolveUserId.new(faraday_error) if message == 'Unable to resolve User Id'

      return faraday_error
    end
  end
end
