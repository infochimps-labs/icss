module Icss

  #
  # Describes an Avro Message
  #
  # A message has attributes:
  #
  # * doc:        an optional description of the message,
  # * request:    a list of named, typed parameter schemas (this has the same form as the fields of a record declaration);
  # * response:   a valid schema for the response
  # * errors:     an optional union of error schemas.
  #
  # A request parameter list is processed equivalently to an anonymous
  # record. Since record field lists may vary between reader and writer, request
  # parameters may also differ between the caller and responder, and such
  # differences are resolved in the same manner as record field differences.
  #
  class Message
    include Receiver
    rcvr_accessor :name,     String
    rcvr_accessor :doc,      String
    rcvr_accessor :request,  Array, :of => Icss::RecordField
    rcvr_accessor :response, Icss::TypeFactory
    rcvr_accessor :errors,   Icss::UnionType
    attr_accessor :protocol

    def after_receive hsh
      @response_is_reference = true if hsh['response'].is_a?(String) || hsh['response'].is_a?(Symbol)
    end

    def path
      File.join(protocol.path, name)
    end

    #
    # Conversion
    #
    def to_hash()
      {
        :doc      => doc,
        :request  => summary_of_request_attr,
        :response => summary_of_response_attr,
        :errors   => (errors && errors.to_hash),
      }.reject{|k,v| v.nil? }
    end
    def to_json() to_hash.to_json ; end

  private
    def summary_of_response_attr
      case when response.blank? then response when @response_is_reference then response.name else response.to_hash end
    end
    def summary_of_request_attr
      (request||[]).map(&:to_hash)
    end
  end
end
