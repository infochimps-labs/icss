module Icss
  class Protocol
    include Receiver

    rcvr :name,        String
    rcvr :namespace,   String
    rcvr :types,       Array, :of => Icss::Type
    rcvr :messages,    Hash,  :of => Icss::Message
    rcvr :data_assets, Array, :of => Icss::DataAsset
    attr_accessor :body
    def after_receive hsh
      self.name = hsh['protocol']
      self.body = hsh
      messages.each{|msg_name, msg| msg.protocol = self; msg.name ||= msg_name }
    end

    def initialize(path, protocol_hash)
      @dirname   = File.dirname(path)
      receive! protocol_hash.to_mash
    end

    #
    # Returns the asset hash with the passed in asset_name
    #
    def asset_for_name nm
      data_assets.find{|asset| asset.named?(nm) }
    end

    #
    # Returns the full type for the passed in asset hash
    #
    def type_for_asset asset
      # types.find{|type| type.name == asset['type']}
      raise 'use asset.type_obj'
    end

    #
    # Given an asset name, returns the the record it points to
    #
    def type_for_asset_name asset_name
      asset = asset_for_name(asset_name)
      type_for_asset(asset)
    end

    #
    # Given an asset name, return the name of the type it points to
    #
    def type_name_for_asset_name asset_name
      asset = asset_for_name(asset_name)
      asset['type']
    end

    #
    # Return the avro record with the given name
    #
    def type_for_name type_name
      # types.find{|record| record.name == type_name}
      Icss::Type.find(type_name)
    end

    #
    # Fetch the avro fields for a named data asset
    #
    def fields_for_asset asset_name
      asset      = asset_for_name(asset_name)
      asset_type = type_for_asset(asset)
      asset_type.fields
    end

    #
    # Fetch the locations on disk of each data asset. WARNING: Assuming relative paths
    #
    def location_for_asset asset_name
      asset = asset_for_name(asset_name)
      File.join(dirname, asset['location'])
    end

    #
    # Return the index of the named field for the named type. Returns (nil) if field
    # does not exist
    #
    def index_of_fieldname asset_name, field_name
      type = type_for_asset_name(asset_name)
      type.index_of_fieldname(field_name)
    end

    AVRO_PIG_MAPPING = {
      'string' => 'chararray',
      'int'    => 'int',
      'long'   => 'long',
      'float'  => 'float',
      'double' => 'double',
      'bytes'  => 'bytearray',
      'fixed'  => 'bytearray'
    }

    #
    # Add pig fields to a passed in array of avro fields
    #
    def augment_with_pig_fields fields
      fields.map{|field| field.body['pig_type'] = AVRO_PIG_MAPPING[field.type]; field }
    end
  end
end
