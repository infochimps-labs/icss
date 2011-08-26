module Icss
  module ReceiverModel
    # Recursively merges using receive
    #
    # Modifies the full receiver chain in-place.
    #
    # For each key in keys,
    # * if self's value is nil, receive the attribute.
    # * if self's attribute is an Array, append to it.
    # * if self's value responds to tree_merge!, tree merge it.
    # * if self's value responds_to merge!, merge! it.
    # * otherwise, receive the value from other_hash
    #
    def tree_merge!(other_hash)
      super(other_hash) do |key, self_val, other_val|
        field = self.class.field_named(key)
        if field && self_val.is_a?(Array) && field.has_key?(:indexed_on)
          index_attr = field[:indexed_on]
          other_val.each do |other_el|
            other_el_name = other_el[index_attr]  or next
            self_el  = self_val.find{|el| el[index_attr].to_s == other_el_name.to_s }
            if self_el then  self_el.tree_merge!(other_el)
            else self_val << other_el
            end
          end
          self_val
        else
          false
        end
      end
      self
    end
  end
end
