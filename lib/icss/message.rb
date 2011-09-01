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

      field :request_decorators, Hash, :default => {:anchors => []}

      field :request,  Array, :items => Icss::Meta::RecordField, :default => []
      field :response, Icss::Meta::TypeFactory
      field :errors,   Object # FIXME: Icss::Meta::UnionType, :default => []
      # this is defined in sample_message_call.rb -- since we don't do referenced types yet
      # field :samples,  Array, :items => Icss::Meta::MessageSample, :default => []

      attr_accessor :protocol

      #we're starting to attach a lot of pork to this lib...
      field :initial_free_qty,      Integer
      field :price_per_k_in_cents,  Integer

      after_receive(:are_my_types_references) do |hsh|
        # track recursion of type references
        @response_referenceness = ! hsh[:response].respond_to?(:each_pair)
        @request_referenceness  = hsh[:request].map{|req| not req.respond_to?(:each_pair) }

        # FIXME: !!! reenable

        # # tie each sample back to this, its parent message
        # (self.samples ||= []).each{|sample| sample.message = self }
      end

      def fullname
        "#{protocol.fullname}.#{basename}"
      end
      def path
        fullname.gsub(%r{\.},'/')
      end

      # the type of the message's params (by convention, its first request field)
      def params_type
        request.first ? request.first.type : {}
      end

      def first_sample_request_param
        req = samples.first.request.first rescue nil
        req || {}
      end

      # ----------------------------------------
      # GEO
      #

      def is_a_geo?
        geolocators.present?
      end

      rcvr_alias(:is_geo, :is_geo)
      def receive_is_geo(val)
        return unless val
        unless defined?(Icss::Meta::Req::Geolocator) then
          warn "View helpers can\'t help with geolocators: Icss::Meta::Req::Geolocator type is missing. Is the catalog loaded properly?"
          return
        end
        self.request_decorators = {
          :anchors => [
            Icss::Meta::Req::PointWithRadiusGeolocator,
            Icss::Meta::Req::AddressTextGeolocator,
            Icss::Meta::Req::TileXYZoomGeolocator,
            # Icss::Meta::Req::BoundingBoxGeolocator,
          ],
        }
      end

      def geolocators
        request_decorators[:anchors]
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
        }.compact
      end
      def to_json(*args) to_hash.to_json(*args) ; end

      private
      def summary_of_response_attr
        case
        when response.blank?        then response
        when @response_referenceness then response.fullname
        else response.to_schema.compact_blank
        end
      end
      def summary_of_request_attr
        request.map do |req|
          case
          when req.blank?             then req
          when @request_referenceness then req.type.fullname
          else                             req.to_schema.compact_blank
          end
        end
      end
    end
  end

end
