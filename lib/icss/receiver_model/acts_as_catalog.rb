require 'active_support/core_ext/module'

# including class is required to implement the following methods:
# * catalog_sections
# * fullname

# including module is required to additionally implement:
# * receive (if not implemented)
# * after_receiver (to register objects) 


module Icss
  module ReceiverModel
    module ActsAsCatalog
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      #
      # Register object in class's registry
      #
      def register(obj)
        self.class.register(obj)
      end
      
      module ClassMethods
        include Icss::ReceiverModel::ActsAsLoadable::ClassMethods
        
        
        #
        # Include ActAsLoadable for file receivers
        # Declare and initialize registry class/module variable to hash
        # Set after_receiver(:register) for classes to register their objects
        #
        def self.extended(base)
          base.class_eval do
            if is_a?(Class)
              include Icss::ReceiverModel::ActsAsLoadable::ClassMethods
              class_attribute :registry
              class_attribute :_catalog_loaded
              after_receive(:register) do |hsh|
                register(self)
              end
            elsif is_a?(Module)
              mattr_accessor :registry
              mattr_accessor :_catalog_loaded
            end
            self.registry = Hash.new
          end
        end
        
        #
        # Add object to registry using fullname method as the identifier
        #
        
        def register(obj)
          registry[obj.fullname] = obj
        end
        
        #
        # Basic ActiveRecord inspired methods
        # Name can include wildcards(*) for simple searching
        #   - example: geo.*.location.*
        #              matches anything with a namespace starting with 'geo'
        #              and containing 'location'
        #
        
        def all(name='*')
          find(:all, name)
        end
        
        def first(name='*')
          find(:first, name)
        end
        
        def last(name='*')
          find(:last, name)
        end
        
        #
        # ActiveRecord inspired find method
        # Params:
        #   1. :all, :first, :last, or registry identifier(ignores wildcards to force exact match)
        #   2. registry name with wildcards(*)
        #         - example: geo.*.location.*
        #
        
        def find(name_or_find_type, name='*')  
          if !self._catalog_loaded
            self._catalog_loaded = true
            load_catalog(true)
          end
                  
          method_name = case name_or_find_type
            when :all then :to_a
            when :first then :first
            when :last then :last
            else
              # If exact match not in registry, try looking in file catalog
              result = (find_in_registry(name_or_find_type, :exact_match => true) || load_files_from_catalog(name_or_find_type, :exact_match => true))
              raise Icss::NotFoundError, "Cannot find #{name_or_find_type}" if result.nil?
              return result
          end

          # If not in registry, try looking in file catalog
          (find_in_registry(name) || load_files_from_catalog(name)).send method_name
        end
        
        def load_from_catalog(fullname)
          filepath = fullname.to_s.gsub(/(\.icss\.yaml)?$/,'').gsub(/\./, '/')
          filenames = catalog_filenames(filepath, [''])
          filenames.each{|filename| receive_from_file(filename) }.compact
        end
        
      private
        #
        # Search registry for matching objects
        # Return single object for exact_match=true
        #
        def find_in_registry(name, args={})
          return registry[name] if args.symbolize_keys[:exact_match]
          
          name = name.to_s.gsub('*', '[^\./]*').gsub(/\.\//, '\.').gsub(/\*$/, '.+') if name.include?('*')
          name_regexp = Regexp.new("^#{name}$", true)
          registry.select{|k, v| k.match(name_regexp) }.values
        end
        
        #
        # Load files from catalog files
        # Namespaces used to correspond to directories
        # Load single file for exact_match=true
        # 
        def load_files_from_catalog(name, args={})
          # don't do anything if name is invalid format          
          if args.symbolize_keys[:exact_match]
            filename = catalog_filenames(name.to_s.gsub(/\./, '/'))[0]
            receive_from_file(filename) if filename
          elsif /\A([A-Za-z_\*]\w*\.?)+\Z/ === name
            filename = name.to_s.gsub(/(\.icss\.yaml)?$/,'').gsub(/\./, '/').gsub(/\*$/, '**/*')
            filenames = catalog_filenames(filename)
            filenames.collect{|filename| receive_from_file(filename) } unless filenames.empty?
          end
          # Return object/s from registry after loading files
          # Useful for unexpected file contents / protocols containing many types
          find_in_registry(name, args)
        end
              
        #
        # Expand filenames to full paths using catalog_root, catalog_sections, and provided filename
        #
        def catalog_filenames(filename='*',catalog_sections=catalog_sections)
          catalog_sections.collect{ |section|
            Dir[File.join(Settings[:catalog_root], section, filename + '.icss.yaml')] }.flatten
        end
    
        #
        # Conditional empty registry and load all found files
        #
        def load_catalog(flush=false)
          flush_registry if flush
          load_files_from_catalog('*')
        end
        
        def flush_registry
          registry.clear
        end
      end
    end
  end
end