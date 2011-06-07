module Icss

  #
  # Describes an Avro Protocol Declaration
  #
  # Avro protocols describe RPC interfaces. The Protocol class will receive an
  # Avro JSON
  #
  # A Protocol has the following attributes:
  #
  # * protocol, a string, the name of the protocol (required). +name+ is
  #   provided as an alias for +protocol+.
  #
  # * namespace, a string that qualifies the name (optional).
  #
  # * doc, a string describing this protocol (optional).
  #
  # * types, an optional list of definitions of named types (records, enums,
  #   fixed and errors). An error definition is just like a record definition
  #   except it uses "error" instead of "record". Note that forward references
  #   to named types are not permitted.
  #
  # * messages, an optional JSON object whose keys are message names and whose
  #   values are objects whose attributes are described below. No two messages
  #   may have the same name.
  #
  # The name and namespace qualification rules defined for schema objects apply
  # to protocols as well: see the documentation for Icss::Type.
  #
  # For example, one may define a simple HelloWorld protocol with:
  #
  #     {
  #       "namespace":    "com.acme",
  #       "protocol":     "HelloWorld",
  #       "doc":          "Protocol Greetings",
  #       "types": [
  #         { "name":     "Greeting",
  #           "type":     "record",
  #           "fields":   [ {"name": "message", "type": "string"} ]},
  #         { "name":     "Curse",
  #           "type":     "error",
  #           "fields":   [ {"name": "message", "type": "string"} ]}
  #       ],
  #       "messages": {
  #         "hello": {
  #           "doc":      "Say hello.",
  #           "request":  [{"name": "greeting", "type": "Greeting" }],
  #           "response": "Greeting",
  #           "errors":   ["Curse"]
  #         }
  #       }
  #     }
  #
  class Protocol
    include Receiver
    include Receiver::ActsAsHash
    include Receiver::ActsAsLoadable
    include Icss::Validations

    rcvr_accessor :protocol,    String, :required => true
    alias_method  :name, :protocol
    rcvr_accessor :namespace,   String # must be *dotted* ("foo.bar"), not slashed ("foo/bar")
    rcvr_accessor :doc,         String
    #
    rcvr_accessor :types,       Array, :of => Icss::TypeFactory, :default => []
    rcvr_accessor :messages,    Hash,  :of => Icss::Message,     :default => {}
    # extensions to avro
    rcvr_accessor :data_assets, Array, :of => Icss::DataAsset,   :default => []
    rcvr_accessor :code_assets, Array, :of => Icss::CodeAsset,   :default => []
    rcvr_accessor :targets,     Hash,  :of => Icss::TargetListFactory, :default => {}, :merge_as => :hash_of_arrays
    rcvr_accessor :under_consideration, Boolean
    rcvr_accessor :update_frequency, String # must be of the form daily, weekly, monthly, quarterly, never

    # attr_accessor :body
    after_receive do |hsh|
      # Set each message's protocol to self, and if the name wasn't given, set
      # it using the message's hash key.
      self.messages.each{|msg_name, msg| msg.protocol = self; msg.name ||= msg_name }
      # Set all the type's parent to self (for namespace resolution)
      self.types.each{|type| type.parent  = self }
      validate_name
      validate_namespace
    end

    # String: namespace.name
    def fullname
      [namespace, name].compact.join(".")
    end

    def path
      fullname.gsub('.', '/')
    end

    def find_message nm
      return if messages.blank?
      nm = nm.to_s.gsub("/", ".").split(".").last
      messages[nm]
    end

    def receive_protocol nm
      namespace_and_name = nm.to_s.gsub("/", ".").split(".")
      self.protocol  = namespace_and_name.pop
      self.namespace = namespace_and_name.join('.')
    end

    def receive_targets hsh
      self.targets = hsh.inject({}) do |target_obj_hsh, (target_name, target_info_list)|
        target_obj_hsh[target_name] = TargetListFactory.receive(target_info_list, target_name) # returns an arry of targets
        target_obj_hsh
      end
    end

    def to_hash()
      {
        :namespace   => @namespace, # use accessor so unset namespace isn't given
        :protocol    => protocol,
        :doc         => doc,
        :under_consideration => under_consideration,
        :update_frequency    => update_frequency,
        :types       => (types       && types.map(&:to_hash)),
        :messages    => messages.inject({}){|h,(k,v)| h[k] = v.to_hash; h },
        :data_assets => data_assets.map(&:to_hash),
        :code_assets => code_assets.map(&:to_hash),
        :targets     => targets_to_hash,
      }.reject{|k,v| v.nil? }.tree_merge! self.message_samples_hash
    end

    def targets_to_hash
      return unless targets
      targets.inject({}) do |hsh,(k,targs)|
        hsh[k] = targs.map(&:to_hash).map(&:compact) ; hsh
      end
    end

    # This will cause funny errors when it is an element of something that's to_json'ed
    def to_json(*args) to_hash.to_json(*args) ; end
  end
end
