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
    rcvr_accessor :request,  Array
    rcvr_accessor :response, Object
    rcvr_accessor :error,    Object
    rcvr          :url,      String
    attr_accessor :message

    # The URL implied by the given hostname and the sample request parameters.
    #
    # @param [String] hostname  The hostname or hostname:port to include in the URL
    # @param [Hash]   extra_query_params A hash of extra params to in
    #
    # The URI expects string values in the hash used to build the query -- if
    # calling #to_s on a field won't do what you want, clobber the value beforehand.
    #
    def url hostname, extra_query_params={}
      host, port = hostname.split(':', 2)
      url = Addressable::URI.new(:host => host, :port => port, :path => ("/"+message.path), :scheme => 'http')
      qq = query_hash.merge(extra_query_params)
      qq.each{|k,v| qq[k] = v.to_s }
      url.query_values = qq
      url
    end

    def query_hash
      request.first.to_hash
    end

    # @param [String] url a URL to strip for query parameters
    #   the URL can be fully-qualified (htttp://api.infochimps.com/this/that?the=other) or relative (this/that?the=other)
    #   the path must match that of the message
    #
    def receive_url url
      warn "sample request url should have a '?' introducing its query parameters" unless url.include?("?")
      parsed_url = Addressable::URI.parse(url)
      receive_request [parsed_url.query_values]
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
      raw = fetch_raw_response( url(hostname, extra_query_params) )
      begin
        self.response = JSON.load(raw)
      rescue StandardError => e
        warn ["error parsing response: #{e}"].join("\n")
        self.response = { :_parse_error => e.to_s }
      end
    end

  private

    def fetch_raw_response host_url
      begin
        RestClient.get(host_url.to_s)
      rescue StandardError => e
        warn ["error fetching response: #{e}"].join("\n")
        { :_fetch_error => e.to_s, :_host_url => host_url.to_s }.to_json
      end
    end
  end
end

class Icss::Message
  rcvr_accessor :samples, Array, :of => Icss::SampleMessageCall

  # tie each samples back to this, its parent message
  # HACK: this doesn't chain off the method defined in message.rb, it just copy/pastes it. This will lead to grief someday.
  def after_receive hsh, *args
    @response_is_reference = true if hsh['response'].is_a?(String) || hsh['response'].is_a?(Symbol)
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
          "request"  => sample_req.request,
          "response" => sample_req.response,
          "error"    => sample_req.error,
          "url"      => "?"+sample_req.url('').query,
          "doc"      => sample_req.doc,
        }
        hsh["messages"][msg_name]["samples"] << sample_hsh.compact_blank!
      end
    end
    return hsh
  end

end
