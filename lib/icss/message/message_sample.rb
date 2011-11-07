module Icss
  module Meta
    #
    # Holds a sample call for a message and its expected response
    #
    # You may define the request parameters using an array of parameters
    # or with the corresponding URL it would render to.
    #
    # This file also decorates Icss::Meta::Message and Icss::Meta::Protocol with helper methods for sample calls.
    #
    class MessageSample
      include ReceiverModel
      field         :name,         String
      field         :doc,          String
      field         :request,      Array, :default => []
      field         :response_hsh, Hash  # a hash suitable for populating the message's @response@ type
      field         :response,     Hash
      attr_accessor :raw_response         # the raw http response from fetching
      field         :error,        String
      field         :url,          String
      attr_accessor :message

      # Whips up the class implied by the ICSS type of this message's response,
      # and populates it using the response hash.
      def response_obj
        return if response.blank?
        message.response.receive(response)
      end

      # The URL implied by the given hostname and the sample request parameters.
      #
      # @param [String] hostname  The hostname or hostname:port to include in the URL
      # @param [Hash]   extra_query_params A hash of extra params to in
      #
      # The URI expects string values in the hash used to build the query -- if
      # calling #to_s on a field won't do what you want, clobber the value beforehand.
      #
      def full_url hostname, extra_query_params={}
        host, port = hostname.split(':', 2)
        u = Addressable::URI.new(:host => host, :port => port, :path => self.path, :scheme => 'http')
        u.query_values = query_hash(extra_query_params)
        u
      end

      def query_hash extra_query_params={}
        hsh = (@url.present? ? @url.query_values : request.first.to_hash) rescue {}
        hsh = hsh.merge extra_query_params
        hsh.each{|k,v| hsh[k] = v.to_s }
        hsh
      end

      def path
        ((@url && @url.path).present? ? @url.path : "/#{message.path}" )
      end

      # @param [String, Addressable::URI]
      #   the URL can be fully-qualified (htttp://api.infochimps.com/this/that?the=other) or relative (this/that?the=other)
      #   and the path must match that of the message.
      #
      def url= new_url
        if new_url.is_a?(String)
          unless new_url.include?('?') then warn "sample request url should have a '?' introducing its query parameters: {#{new_url}}" ; end
          new_url = Addressable::URI.parse(new_url)
        end
        @url = new_url
      end

      # retrieve the response from the given host, storing it in response.  this
      # catches all server errors and constructs a dummy response hash if the call
      # fails.
      def fetch_response! hostname="", extra_query_params={}
        self.raw_response = fetch_raw_response( full_url(hostname, extra_query_params) )
        begin
          resp_hsh = JSON.load(raw_response.body)
        rescue StandardError => e
          warn ["  error parsing response: #{e}"].join("\n")
          self.response = nil
          self.error    = "JsonParseError"
          return
        end
        if raw_response.code == 200
          self.response = resp_hsh
          self.error    = nil
        else
          self.response = nil
          self.error    = resp_hsh["error"]
        end
      end

      protected

      def fetch_raw_response full_url
        RestClient.get(full_url.to_s) do |response, request, result|
          response
        end
      end
    end
  end

end

class Icss::Meta::Message
  field :samples, Array, :items => Icss::Meta::MessageSample, :default => []
end

class Icss::Meta::Protocol

  #
  # a hash for dumping to file:
  # @example: from the whole thing, would dump only this:
  #
  #     namespace: util.time
  #     protocol: chronic
  #     messages:
  #       parse:
  #         samples:
  #           - url:            "?now=5%3A06%3A07%202010-08-08&time_str=Yesterday"
  #             response:       { "time": "2010-08-07 05:06:07 UTC", "epoch_seconds": 1281225967 }
  #
  def message_samples_hash
    hsh = { :namespace => namespace, :protocol => protocol, :messages => {} }
    messages.each do |msg_name, msg|
      hsh[:messages][msg_name] = { :samples => [] }
      msg.samples.each do |sample_req|
        sample_hsh = {
          :name     => sample_req.name,
          :doc      => sample_req.doc,
        }
        if sample_req.response.present?
        then sample_hsh[:response] =  sample_req.response
        else sample_hsh[:error]    =  sample_req.error
        end
        if sample_req.url.present?
        then sample_hsh[:url]      = sample_req.url.to_s
        else sample_hsh[:request]  = sample_req.request
        end
        sample_hsh.compact_blank!
        hsh[:messages][msg_name][:samples] << sample_hsh
      end
    end
    return hsh
  end

end
