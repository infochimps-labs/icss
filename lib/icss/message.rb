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
    rcvr_accessor :errors,   Array, :of => Icss::TypeFactory
    attr_accessor :protocol

    #
    # Conversion
    #
    def to_hash()
      { :request  => (request||[]).map(&:to_hash),
        :response => response.to_hash,
        :errors   => (errors && errors.map(&:to_hash)),
        :doc      => doc }.reject{|k,v| v.nil? }
    end
    def to_json() to_hash.to_json ; end
  end
end
