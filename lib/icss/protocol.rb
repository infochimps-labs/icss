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
      include Icss::ReceiverModel::ActsAsCatalog

      field :protocol,    String, :required => true, :validates => { :format => { :with => /\A[A-Za-z_]\w*\Z/, :message => "must start with [A-Za-z_] and contain only [A-Za-z0-9_]." } }
      alias_method  :basename, :protocol
      field :namespace,   String, :required => true, :validates => { :format => { :with => /\A([A-Za-z_]\w*\.?)+\Z/, :message => "Segments that start with [A-Za-z_] and contain only [A-Za-z0-9_], joined by '.'dots" } }
      field :title,       String
      field :doc,         String
      field :aliases,     Array, :items => String,                  :default => []
      #
      field :types,       Array, :items => Icss::Meta::TypeFactory, :default => []
      field :_doc_hints,  Hash,  :default => {}

      field :messages,    Hash,  :values => Icss::Meta::Message,     :default => {}
      field :data_assets, Array, :items  => Icss::Meta::DataAsset,   :default => []
      field :code_assets, Array, :items  => Icss::Meta::CodeAsset,   :default => []
      field :targets,     Hash,  :values => Icss::TargetListFactory, :default => {}, :merge_as => :hash_of_arrays
      
      field :tags,        Array, :items => String, :default => []
      field :categories,  Array, :items => String, :default => []
      field :license_id,  String
      field :credits,     Hash,  :values=> String, :default => {} # hash of source_ids
      
      def license
        Icss::Meta::License.find(license_id) unless license_id.blank?
      end  
      
      def sources
        @sources ||= credits.inject(Hash.new){|hash, credit| hash[credit[0].to_sym] = Icss::Meta::Source.find(credit[1]); hash }
      end

      field :under_consideration, Boolean
      field :update_frequency, String, :validates => { :format => { :with => /daily|weekly|monthly|quarterly|never/ }, :allow_blank => true }
      rcvr_remaining :_extra_params

      after_receive(:parent_my_messages) do |hsh|
        # Set each message's protocol to self, and if the basename wasn't given, set
        # it using the message's hash key.
        self.messages.each{|msg_name, msg| msg.protocol = self; msg.basename ||= msg_name }
      end
      after_receive(:warn_if_invalid) do |hsh|
        warn errors.inspect unless valid?
        warn "Extra params #{_extra_params.keys.inspect} given to #{self.fullname}" if _extra_params.present?
      end
      after_receive(:declare_core_types) do |hsh|
        self.types.each{|type| type.respond_to?(:_schema) && (type._schema.is_core = (self.fullname  == "icss.core.typedefs")) }
      end
      after_receive(:fix_legacy_catalog_info) do
        if targets[:catalog].present?
          catalog = targets[:catalog].first
          if self.title.blank? then self.title = catalog.title ; end
          if self.tags.blank? then self.tags = catalog.tags ; end
          if self.doc.blank? then self.doc = catalog.description; end
          if self.data_assets.blank? && catalog.link.present?
            data_asset = { :name => catalog.name,
                           :location => (catalog.link.match(/^http/) ? '' : 'http://') + catalog.link,
                           :asset_type => :offsite }
            self.data_assets << Icss::Meta::DataAsset.receive(data_asset)
          end
        end
      end

      # String: namespace.basename
      def fullname
        [namespace, basename].compact.join(".")
      end

      # a / separated version of the fullname, with no / at start
      def path
        fullname.gsub('.', '/')
      end

      def find_message nm
        return if messages.blank?
        nm = nm.to_s.gsub("/", ".").split(".").last
        messages[nm]
      end

      def receive_types(types)
        # this is a horrible, horrible kludge so that types with simple names ('bob') can become
        # properly namespaced ('foo.bar.bob') even when they haven't met their parents (and even 
        # where the calls to receive types are nested/recursive)
        Icss::Meta::TypeFactory.with_namespace(namespace) do
          super(types)
        end
      end

      def receive_messages(types)
        # this is a horrible, horrible kludge so that messages with simple names ('do_bob') can become
        # properly namespaced ('foo.bar.do_bob') even when they haven't met their parents (and even 
        # where the calls to receive_messages are nested/recursive)
        Icss::Meta::TypeFactory.with_namespace(namespace) do
          super(types)
        end
      end

      def receive_protocol(nm)
        name_segs = nm.to_s.gsub("/", ".").split(".")
        self.protocol  = name_segs.pop
        self.namespace = name_segs.join('.') if name_segs.present?
      end

      def receive_targets(tgts)
        return unless tgts.present?
        self.targets ||= {}
        tgts.symbolize_keys!.each do |target_name, target_info_list|
          targets[target_name] = TargetListFactory.receive(target_info_list, target_name) # array of targets
        end
        targets
      end
      
      def self.catalog_sections
        ['core', 'datasets', 'old', 'legacy/datasets']
      end

      def to_hash()
        {
          :namespace   => @namespace, # use accessor so unset namespace isn't given
          :protocol    => protocol,
          :title       => title,
          :license_id  => license_id,
          :credits     => credits,
          :tags        => tags,
          :categories  => categories,
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
