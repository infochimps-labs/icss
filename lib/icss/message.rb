module Icss
  module Meta
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
      include ::Icss::ReceiverModel

      field :name,     String
      alias_method :basename,  :name
      alias_method :basename=, :name=
      field :doc,      String

      #we're starting to attach a lot of pork to this lib...
      field :initial_free_qty,      Integer
      field :price_per_k_in_cents,  Integer

      field :request,  Array, :type => :array, :default => [], :items => Icss::Meta::RecordField
      field :response, Icss::Meta::TypeFactory
      field :errors,   Object # FIXME: Icss::Meta::UnionType, :default => []
      attr_accessor :protocol
      # this is defined in sample_message_call.rb -- since we don't do referenced types yet
      field :samples,  :array, :default => [], :items => Object # FIXME: Icss::SampleMessageCall

      after_receive do |hsh|
        # track recursion of type references
        @response_is_reference = true if hsh['response'].is_a?(String) || hsh['response'].is_a?(Symbol)


        # FIXME: !!! reenable

        # # tie each sample back to this, its parent message
        # (self.samples ||= []).each{|sample| sample.message = self }


      end

      def path
        File.join(protocol.path, name)
      end

      def first_sample_request_param
        req = samples.first.request.first rescue nil
        req || {}
      end

      #
      # Conversion
      #
      def to_hash()
        {
          :request  => summary_of_request_attr,
          :response => summary_of_response_attr,
          :doc      => doc,
          :errors   => (errors.blank? ? nil : errors),
          # :samples  => samples.map(&:to_hash).map(&:compact_blank),
          :initial_free_qty => initial_free_qty,
          :price_per_k_in_cents => price_per_k_in_cents,
        }.reject{|k,v| v.nil? }
      end
      def to_json(*args) to_hash.to_json(*args) ; end

      private
      def summary_of_response_attr
        case
        when response.blank?        then response
        when @response_is_reference then response.basename
        else response.to_schema.compact_blank
        end
      end
      def summary_of_request_attr
        request.map(&:to_hash).compact_blank
      end
    end
  end

end
