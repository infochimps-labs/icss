
describe Icss::Meta::RecordField do
  context 'asdf.receive' do
    it 'is' do
      (Icss::Meta::RecordField.public_methods - Class.public_methods).sort.should == [
        :add_receiver, :after_receive, :after_receivers, :consume_tuple,
        :doc, :doc=, :field, :field_names, :fields,
        :fullname, :namespace,
        :rcvr_remaining, :receive, :to_schema, :tuple_keys, :typename
      ]
    end
    it 'works' do
      hsh = { :name => :height, :type => Integer, :doc => 'How High',
        :default  => 3, :required => false, :order => 'ascending', }
      foo = Icss::Meta::RecordField.receive(hsh)
      foo.required.should be_false
      foo.default.should == 3
      foo.to_hash.should == hsh
      foo.receive_order('descending')
      foo.order.should == 'descending'
    end
  end
end
