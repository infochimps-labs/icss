module Icss
  #
  # Holds a sample call for a message and its expected response
  #
  # You may define the request parameters using an array of parameters
  # or with the corresponding URL it would render to.
  #
  # This file also decorates Icss::Message and Icss::Protocol with helper methods for sample calls.
  #
  class SampleMessageCall
    include Receiver
    rcvr_accessor :name,     String
    rcvr_accessor :doc,      String
    rcvr_accessor :request,  Array, :default => []
    rcvr_accessor :response, Object
    rcvr_accessor :error,    Object
    rcvr_accessor :url,      String
    attr_accessor :message

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
      hsh.merge! extra_query_params
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

    # Whips up the class implied by the ICSS type of this message's response,
    # and populates it using the response hash.
    def response_obj
      return if response.blank?
      klass = message.response.ruby_klass
      klass.receive(response.compact_blank!)
    end

    # retrieve the response from the given host, storing it in response.  this
    # catches all server errors and constructs a dummy response hash if the call
    # fails.
    def fetch_response! hostname="", extra_query_params={}
      raw = fetch_raw_response( full_url(hostname, extra_query_params) )
      begin
        self.response = JSON.load(raw)
      rescue StandardError => e
        warn ["error parsing response: #{e}"].join("\n")
        self.response = { :_parse_error => e.to_s }
      end
    end

  private

    def fetch_raw_response full_url
      begin
        RestClient.get(full_url.to_s)
      rescue StandardError => e
        warn ["error fetching response: #{e}"].join("\n")
        { :_fetch_error => e.to_s, :_full_url => full_url.to_s }.to_json
      end
    end
  end
end

class Icss::Message
  rcvr_accessor :samples, Array, :of => Icss::SampleMessageCall

  # tie each samples back to this, its parent message
  after_receive do |hsh|
    (self.samples ||= []).each{|sample| sample.message = self }
  end
end

class Icss::Protocol

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
    hsh = { "namespace" => namespace, "protocol" => protocol, "messages" => {} }
    messages.each do |msg_name, msg|
      hsh["messages"][msg_name] = { "samples" => [] }
      msg.samples.each do |sample_req|
        sample_hsh = {
          "name"     => sample_req.name,
          "response" => sample_req.response,
          "error"    => sample_req.error,
          "doc"      => sample_req.doc,
        }
        if sample_req.url.present?
        then sample_hsh['url']     = sample_req.url.to_s
        else sample_hsh['request'] = sample_req.request
        end
        hsh["messages"][msg_name]["samples"] << sample_hsh.compact_blank!
      end
    end
    return hsh
  end

end
