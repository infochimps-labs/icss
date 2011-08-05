require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'
require 'icss/type/new_factory'

# it 'Icss::Something::Doohickey describes behavior of a "doohickey"; Icss::Something::Doohickey instances embody individual doohickeys; Icss::Meta::Something::DoohickeyType mediates the type description'

module Icss::Smurf
  class Base
    include Icss::Meta::RecordType
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    include Icss::Meta::RecordType
    field :doing_it, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    include Icss::Meta::RecordType
    field :blondness, Integer
  end
end

module Howdy
module Bob
  include Icss::Meta::RecordType

  field :my_happy_field,       String

  p [doc, namespace, fullname, name, typename]
  self.doc = "I am BOB"
  p [doc, namespace, fullname, name, typename]
end

class Fred
  p [(self.methods - Class.methods), (self.new.methods - Object.new.methods)]
  include Icss::Meta::RecordType
  p [(self.methods - Class.methods), (self.new.methods - Object.new.methods)]

  field :my_happy_field,       String
  field :my_readonly_field,    String, :writer => :none

  p [(self.methods - Class.methods), (self.new.methods - Object.new.methods)]

  p [doc, namespace, fullname, name, typename]
  self.doc       = "I am Fred"
  p [doc, namespace, fullname, name, typename]
end

class SubFred < Fred
end

end

describe Icss::Meta::RecordType do
  it 'has a doc field' do
    # Icss::Meta::RecordType.doc = "All about me!"
    # Icss::Meta::RecordType.doc.should == "All about me!"
  end

  it 'Bob' do
    fd = [Howdy::Fred.doc ] rescue :err
    bd = [Howdy::Bob.doc ] rescue :err
    fn = Howdy::Fred.new ; fn.my_happy_field = 3
    p [fd, bd, fn, Howdy::Bob.fields, Howdy::Bob.doc, Howdy::Fred.doc, Howdy::SubFred.doc]
  end
end

describe Icss::Meta::RecordType do
  let(:new_smurf_klass){    k = Class.new(Icss::Smurf::Poppa)  }

  context '.field' do
    it 'adds field names' do
      Icss::Smurf::Base.field_names.should == [:smurfiness]
    end
    it 'adds field info' do
      Icss::Smurf::Base.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer} }
    end
    it 'inherits parent fields' do
      new_smurf_klass.field(:birthday, Date)
      Icss::Smurf::Poppa.field_names.should == [:smurfiness]
      Icss::Smurf::Poppa.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer} }
      new_smurf_klass.field_names.should == [:smurfiness, :birthday]
      new_smurf_klass.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer}, :birthday => {:name => :birthday, :type => Date} }
    end

    # context 'decorates the Meta module of the class' do
    #   it 'with accessors'
    #   it 'with the appropriate receive_foo method'
    #   it 'with new entry in .fields'
    # end
    #
    # it "sets the field's name"
    #
    # context 'type' do
    #   it 'class uses that class'
    #   it 'string looks up the class'
    #   it ':remaining instruments rcvr_remaining'
    # end
  end

  context 'instances' do
    let(:poppa    ){ Icss::Smurf::Poppa.new() }
    let(:smurfette){ Icss::Smurf::Smurfette.new() }

    it 'have accessors for each field' do
      [:smurfiness, :doing_it, :blondness].each do |f|
        smurfette.should respond_to(f)
        smurfette.should respond_to("#{f}=")
      end
      smurfette.blondness.should == nil
      smurfette.blondness = true
      smurfette.blondness.should == true
    end
  end

  #   context ':default =>' do
  #     it 'try_dups the object on receipt'
  #     it 'try_dups the object when setting default'
  #     it 'creates an after_receive hook to set the default'
  #     it 'accepts a proc'
  #
  #   end
  #
  #   context ':order =>' do
  #   end
  #
  #   context ':required =>' do
  #     it 'adds a validator'
  #   end
  #
  #   context ':validates' do
  #     context 'length' do
  #       # { :is => :==, :minimum => :>=, :maximum => :<= }.freeze
  #     end
  #
  #     it 'exclusion (on container type)'
  #     it 'format'
  #     it 'numericality' do
  #       # { :greater_than => :>, :greater_than_or_equal_to => :>=, :equal_to => :==, :less_than => :<, :less_than_or_equal_to => :<=, :odd => :odd?, :even => :even? }.freeze
  #     end
  #     it 'presence'
  #     it 'uniqueness'
  #   end
  #
  #   context ':index => ' do
  #     it 'primary key'
  #     it 'foreign key'
  #     it 'uniqueness constraint'
  #   end
  #
  #   # context ':accessor / :reader / :writer' do
  #   #   it ':private         -- attr_whatever is private'
  #   #   it ':protected       -- attr_whatever is protected'
  #   #   it ':none            -- no accessor/reader/writer'
  #   # end
  #
  #   context ':after_receive'
  #
  #   context ':i18n_key'
  #   context ':human_name => '
  #   context ':singular_name => '
  #   context ':plural_name => '
  #   context ':uncountable => '
  #
  #   context :serialization
  #   it '#serializable_hash'
  #
  #   # constant
  #   # mass assignment security: accessible,
  #
  #   it 'works on the parent Meta module type, not '
  #

  # context 'is a "type"' do
  #   it "with namespace, name, fullname, and doc" do
  #     [:namespace, :name, :fullname, :doc ]
  #   end
  #
  # end
  #
  # context 'is_a (inheritance)' do
  #   it 'knows its direct Icss superclass'
  #   it 'knows its Icss mixin classes'
  # end
  #
  # context 'synthesizing' do
  #   it 'has a Meta model to '
  # end
  #
  # context 'has properties' do
  #   it 'described by its #fields'
  #
  #   context 'container types' do
  #
  #     it 'field foo, Array, :of   => FooClass validates instances are is_a?(FooClass)'
  #     it 'field foo, Array, :with => FooFactory validates instances are is_a?(FooFactory.product_klass)'
  #
  #     it ''
  #
  #   end
  # end
  #
  # context 'special properties' do
  #   it '_domain_id_field'
  #   it '_primary_location_field'
  #   it '_slug' # ??
  # end
  #
  # context 'name' do
  #   context ':i18n_key'
  #   context ':human_name => '
  #   context ':singular_name => '
  #   context ':plural_name => '
  #   context ':uncountable => '
  # end

end



# describe Icss::Meta::RecordType::FieldDecorators do
#
#   #
#   let(:module_smurf){ m = Module.new; m.send(:include, Icss::Meta::RecordType) ; m }
#
#   context '.fields' do
#     #
#     it 'inheritance works without weirdness' do
#       Icss::Smurf::Poppa.field_names.should     == [:smurfiness]
#       Icss::Smurf::Smurfette.field_names.should == [:smurfiness, :doing_it, :blondness]
#       Icss::Smurf::Brainy.field_names.should    == [:doing_it]
#     end
#     #
#     it 'fields dynamically added to superclasses appear, in order of ancestry' do
#       new_smurf_klass.send(:include, module_smurf)
#       module_smurf.field_names.should == []
#       new_smurf_klass.field_names.should    == [:smurfiness]
#       #
#       module_smurf.field(:smurfberries, Integer)
#       new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries]
#       #
#       new_smurf_klass.field(:singing, Boolean)
#       module_smurf.field(:smurfberry_crunch, Integer)
#       new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries, :smurfberry_crunch, :singing]
#     end
#     #
#     it 're-announcing a field modifies its info hash downstream, but not its order' do
#       uncle_smurf = Class.new(Icss::Smurf::Poppa)
#       baby_smurf  = Class.new(uncle_smurf)
#       uncle_smurf.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Integer} }
#       baby_smurf.fields.should    == {:smurfiness => {:name => :smurfiness, :type => Integer} }
#       #
#       uncle_smurf.field(:smurfiness, Float, :by_the_way => 'pull my finger')
#       Icss::Smurf::Poppa.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Integer} }
#       uncle_smurf.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Float, :by_the_way => 'pull my finger'} }
#       baby_smurf.fields.should    == {:smurfiness => {:name => :smurfiness, :type => Float, :by_the_way => 'pull my finger'} }
#     end
#   end
# end



# describe Icss::Meta::TypeFactory do
#   module Icss
#     module This
#       module That
#         class TheOther
#         end
#       end
#     end
#     Blinken = 7
#   end
#
#   context '.ensure_module_scope' do
#     it 'adds a new child when parents exist' do
#       Icss::This::That.should_not be_const_defined(:AlsoThis)
#       new_module = Icss::Meta::TypeFactory.get_module_scope(%w[Icss This That AlsoThis])
#       new_module.name.should == 'Icss::This::That::AlsoThis'
#       Icss::This::That::AlsoThis.class.should == Module
#       Icss::This::That.send(:remove_const, :AlsoThis)
#     end
#     it 'adds parents as necessary' do
#       Icss.should_not be_const_defined(:Winken)
#       new_module = Icss::Meta::TypeFactory.get_module_scope(%w[Icss Winken Blinken Nod])
#       new_module.name.should == 'Icss::Winken::Blinken::Nod'
#       Icss::Winken::Blinken::Nod.class.should == Module
#       Icss::Winken::Blinken.class.should      == Module
#       Icss::Winken.class.should               == Module
#       Icss.send(:remove_const, :Winken)
#     end
#   end
#
#   context '.make' do
#     it 'succeeds when the class already exists' do
#       klass, meta_module = Icss::Meta::TypeFactory.make('this.that.the_other')
#       klass.should be_a(Class)
#       klass.name.should == 'Icss::This::That::TheOther'
#       meta_module.should be_a(Module)
#       meta_module.name.should == 'Icss::Meta::This::That::TheOtherType'
#     end
#     it 'succeeds when the class does not already exist' do
#       Icss.should_not be_const_defined(:YourMom)
#       klass, meta_module = Icss::Meta::TypeFactory.make('your_mom.wears.combat_boots')
#       klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
#       Icss::Meta::YourMom::Wears::CombatBootsType.class.should == Module
#       Icss::Meta::YourMom::Wears.class.should                  == Module
#       Icss::YourMom::Wears::CombatBoots.class.should           == Class
#       Icss::YourMom::Wears.class.should                        == Module
#       Icss::Meta.send(:remove_const, :YourMom)
#       Icss.send(:remove_const, :YourMom)
#     end
#     it 'includes its meta type as a module' do
#       Icss.should_not be_const_defined(:YourMom)
#       klass, meta_module = Icss::Meta::TypeFactory.make('your_mom.wears.combat_boots')
#       klass.should < Icss::Meta::YourMom::Wears::CombatBootsType
#     end
#   end
# end


# describe Icss::Meta::BaseType do
#   before do
#     @test_protocol_hsh = YAML.load(File.open(File.expand_path(File.dirname(__FILE__) + '/../test_icss.yaml')))
#     @simple_record_hsh = @test_protocol_hsh['types'].first
#   end
#
#   it 'loads from a hash' do
#     Icss::Meta::BaseType.receive!(@simple_record_hsh)
#     p [Icss::Meta::BaseType, Icss::Meta::BaseType.fields]
#     Icss::Meta::BaseType.fields.length.should == 3
#     ref_field = Icss::Meta::BaseType.fields.first
#     ref_field.name.should == 'my_happy_string'
#     ref_field.doc.should  =~ /field 1/
#     ref_field.type.name.should == :string
#   end
#
#   it 'makes a meta type' do
#     k = Icss::Meta::TypeFactory.make('icss.simple_type')
#     meta_type = Icss::RecordType.receive(@simple_record_hsh)
#     p meta_type
#     k.class_eval{ include Receiver }
#     meta_type.decorate_with_receivers(k)
#     meta_type.decorate_with_conveniences(k)
#     meta_type.decorate_with_validators(k)
#     p [k.fields, k.receiver_attr_names]
#   end
#
#
#   # it "has the *class* attributes of an avro record type" do
#   #   [:name, :doc, :fields, :is_a, ]
#   # end
#   #
#   # it "is an Icss::Meta::NamedType, an Icss::Meta::Type, and an Icss::Base" do
#   #   Icss::Meta::RecordType.should < Icss::Meta::NamedType
#   #   Icss::Meta::RecordType.should < Icss::Meta::Type
#   #   Icss::Meta::RecordType.should < Icss::Base
#   # end
#
# end

