# require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
# require 'icss/type'
# require 'icss/type/named_schema'
# require 'icss/type/record_type'
# require 'icss/type/complex_types'
# require 'icss/type/type_factory'
# require 'icss/type/record_field'
#
# describe Icss::Meta::RecordField do
#   context 'asdf.receive' do
#     it 'is' do
#       (Icss::Meta::RecordField.public_methods - Class.public_methods).sort.should == [
#         :add_receiver, :after_receive, :after_receivers,
#         :doc, :doc=, :field, :field_names, :fields,
#         :fullname, :namespace,
#         :rcvr_remaining, :receive, :to_schema, :typename
#       ]
#     end
#     it 'works' do
#       hsh = { :name => :height, :type => 'int', :doc => 'How High',
#         :default  => 3, :required => false, :order => 'ascending', }
#       foo = Icss::Meta::RecordField.receive(hsh)
#       foo.required.should be_false
#       foo.default.should == 3
#       foo.as_json.should == hsh
#       foo.receive_order('descending')
#       foo.order.should == 'descending'
#     end
#   end
# end
