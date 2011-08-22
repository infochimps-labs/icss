module Icss
  module ReceiverModel
    module Validations
      module ::Icss::ReceiverModel::ClassMethods
        include ::Icss::ReceiverModel::Validations
      end

      #
      # Sends the fields' validations on to Icss::Type::Validations.
      # Uses syntax parallel to ActiveModel's:
      #
      #      :presence     => true
      #      :uniqueness   => true
      #      :numericality => true
      #        :==, :>, :>=, :<, :<=, :odd?, :even?
      #        (and spelled out: :equal_to, :less_than_or_equal_to, :odd, etc)
      #      :length       => { :minimum => 0, maximum => 2000 }
      #        :==, :>=, :<=, :is, :minimum, :maximum
      #      :format       => { :with => /.*/ }
      #      :inclusion    => { :in => [1,2,3] }
      #      :exclusion    => { :in => [1,2,3] }
      #
      def add_validator(field_name)
        field = field_named(field_name)
        self.validates(field[:name], :presence => true ) if field[:required]
        self.validates(field[:name], field[:validates] ) if field[:validates]
        super(field_name) if defined?(super)
      end
    end
  end
end
