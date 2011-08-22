Settings = {} unless defined?(Settings)
Settings[:catalog_root] ||= (defined?(Rails) ? (Rails.root+'catalog') : ENV.root_path('examples/infochimps_catalog'))
# Log = Rails.logger if defined?(Rails) && (not defined?(Log))

module Icss
  module Meta

    # predefine so we can use below

    class Message ; end

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
    # to protocols as well: see the documentation for Icss::Meta::Type.
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
      include Icss::ReceiverModel

      field :protocol,    String
      alias_method  :basename, :protocol
      field :namespace,   String
      field :doc,         String
      #
      field :types,       Array, :items => Icss::Meta::TypeFactory, :default => []

      field :messages,    Hash,  :values => Icss::Meta::Message,     :default => {}
      field :data_assets, Array, :items  => Icss::Meta::DataAsset,   :default => []
      field :code_assets, Array, :items  => Icss::Meta::CodeAsset,   :default => []
      field :targets,     Hash,  :values => Icss::TargetListFactory, :default => {}, :merge_as => :hash_of_arrays
      field :under_consideration, Boolean
      field :update_frequency, String

      class_attribute :registry
      self.registry = Hash.new
      after_receive(:register) do |hsh|
        registry[fullname] = self
      end

      validates :protocol,  :presence => true, :format => { :with => /\A[A-Za-z_]\w*\z/, :message => "must start with [A-Za-z_] and contain only [A-Za-z0-9_]." }
      validates :namespace, :presence => true, :format => { :with => /\A([A-Za-z_]\w*\.?)+\z/, :message => "Segments that start with [A-Za-z_] and contain only [A-Za-z0-9_], joined by '.'dots" }
      validates :update_frequency, :format => { :with => /daily|weekly|monthly|quarterly|never/ }, :allow_blank => true

      after_receive(:parent_my_messages) do |hsh|
        # Set each message's protocol to self, and if the basename wasn't given, set
        # it using the message's hash key.
        self.messages.each{|msg_name, msg| msg.protocol = self; msg.basename ||= msg_name }
      end
      after_receive(:warn_if_invalid) do |hsh|
        warn errors.inspect unless valid?
      end

      # String: namespace.basename
      def fullname
        [namespace, basename].compact.join(".")
      end

      # a / separated version of the fullname, with no / at start
      def path
        fullname.gsub('.', '/')
      end

      def self.load_from_catalog(protocol_fullname)
        filepath = protocol_fullname.to_s.gsub(/(\.icss\.yaml)?$/,'').gsub(/\./, '/')+".icss.yaml"
        filepath = File.join(Settings[:catalog_root], filepath)
        Dir[filepath].sort.map do |filename|
          begin
            protocol_hsh = YAML.load(File.open(filename))
            proto = self.receive(protocol_hsh)
            Log.debug(['Loaded', filepath, proto].join("\t")) if defined?(Log)
            proto
          rescue Exception => boom
            warn( [boom.backtrace, "Could not load ICSS file #{filename}: #{boom}" ].flatten.join("\n") )
            nil
          end
        end.compact
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

      def receive_targets tgts
        return unless tgts.present?
        self.targets ||= {}
        tgts.each do |target_name, target_info_list|
          targets[target_name] = TargetListFactory.receive(target_info_list, target_name) # array of targets
        end
        targets
      end

      def to_hash()
        {
          :namespace   => @namespace, # use accessor so unset namespace isn't given
          :protocol    => protocol,
          :doc         => doc,
          :types       => (types       && types.map(&:to_schema)),
          :messages    => messages.inject({}){|h,(k,v)| h[k.to_sym] = v.to_hash; h },
          :data_assets => data_assets.map(&:to_hash).map(&:compact_blank),
          :code_assets => code_assets.map(&:to_hash).map(&:compact_blank),
          :update_frequency    => update_frequency,
          :under_consideration => under_consideration,
          :targets     => targets_to_hash,
        }.reject{|k,v| v.nil? }
      end

      def targets_to_hash
        return unless targets
        targets.inject({}) do |hsh,(k,targs)|
          hsh[k] = targs.map(&:to_hash).map(&:compact_blank) ; hsh
        end
      end

      # This will cause funny errors when it is an element of something that's to_json'ed
      def to_json(*args) to_hash.to_json(*args) ; end
    end
  end

end
