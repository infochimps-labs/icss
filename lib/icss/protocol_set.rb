# you must require 'icss/protocol_set' explicitly to use it.

module Icss
  #
  # Holds a set of icss protocols, with helper methods to load them from a
  # directory tree, to merge in a protocol set yaml file, and so forth
  #
  class ProtocolSet
    attr_accessor :protocols

    def initialize
      self.protocols = {}
    end


    def register pr
      if protocols[pr.fullname]
        protocols[pr.fullname].tree_merge!(pr)
      else
        protocols[pr.fullname] = pr
      end
    end

    # load and register the protocols in the given filenames
    def load_protocols *icss_filenames
      icss_filenames = icss_filenames.flatten.compact
      icss_filenames.each do |icss_filename|
        register Icss::Protocol.receive_from_file(icss_filename)
      end
    end

    # load and register the set of protocols in the given yaml file.
    # it must be a hash with element 'protocol_set', holding an array of
    # protocol hashes.
    #
    #   protocol_set:
    #     - namespace: "..."
    #       protocol:  "..."
    def load_protocol_set protocol_set_filename
      protocol_set_hsh = YAML.load(File.open(protocol_set_filename))
      protocol_set_hsh['protocol_set'].each do |hsh|
        register Icss::Protocol.receive(hsh)
      end
    end
  end
end


