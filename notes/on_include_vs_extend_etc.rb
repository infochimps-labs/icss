#!/usr/bin/env ruby



# klass         Foo                     [:module_self_foo, :module_meth_extif]
# sgtncl        Foo                     []
# ---------------
# obj           ClassIncludingFoo       [:meth_in_class,                          :module_meth_foo, :module_meth_inclif]
# klass         ClassIncludingFoo       [:meth_in_sgtn_cl,   :self_meth_in_class, --                -- ]
# sgtncl        ClassIncludingFoo       [:self_meth_sgtn_cl, --                   --                -- ]
# ---------------
# obj           ClassExtendingFoo       [:meth_in_class,     --                   --                -- ]
# klass         ClassExtendingFoo       [:meth_in_sgtn_cl,   :self_meth_in_class, :module_meth_foo, :module_meth_inclif]
# sgtncl        ClassExtendingFoo       [:self_meth_sgtn_cl, --                   --                -- ]
# ---------------
# obj           ClassInclFooInSgtnCl    [:meth_in_class,     --                   --                -- ]
# klass         ClassInclFooInSgtnCl    [:meth_in_sgtn_cl,   :self_meth_in_class, :module_meth_foo, :module_meth_inclif]
# sgtncl        ClassInclFooInSgtnCl    [:self_meth_sgtn_cl, --                   --                -- ]
# ---------------
# obj           ClassExtFooInSgtnCl     [:meth_in_class,     --                 , --                -- ]
# klass         ClassExtFooInSgtnCl     [:meth_in_sgtn_cl,   :self_meth_in_class, --                -- ]
# sgtncl        ClassExtFooInSgtnCl     [:self_meth_sgtn_cl,                      :module_meth_foo, :module_meth_inclif]
#
#
# Ancestor chain
#
# klass         Foo                             IncludedInFoo
# sgtncl        ExtendedInFoo                                           Module  Object  Kernel  BasicObject
# #
# klass         ClassExtendingFoo                               SimpleClass     Object  Kernel  BasicObject
# sgtncl                                Foo     IncludedInFoo   Class   Module  Object  Kernel  BasicObject
# #
# klass         ClassIncludingFoo       Foo     IncludedInFoo   SimpleClass     Object  Kernel  BasicObject
# sgtncl                                                        Class   Module  Object  Kernel  BasicObject
# #
# klass         ClassInclFooInSgtnCl                            SimpleClass     Object  Kernel  BasicObject
# sgtncl                                Foo     IncludedInFoo   Class   Module  Object  Kernel  BasicObject
# #
# klass         ClassExtFooInSgtnCl                             SimpleClass     Object  Kernel  BasicObject
# sgtncl                                                        Class   Module  Object  Kernel  BasicObject


# --------------- Foo
# module_meth_extif                     class   Foo                             Module
# module_self_foo                       class   Foo                             Module
#
# --------------- ClassExtendingFoo
# meth_in_class                         obj     #<ClassExtendingFoo:0x00000100e ClassExtendingFoo
# self_meth_in_class                    class   ClassExtendingFoo               Class                           #<Class:ClassExtendingFoo>
# meth_in_sgtn_cl                       class   ClassExtendingFoo               Class                           #<Class:ClassExtendingFoo>
# self_meth_sgtn_cl                     sgtn_cl #<Class:ClassExtendingFoo>      Class
# module_meth_foo                       class   ClassExtendingFoo               Class                           #<Class:ClassExtendingFoo>
# module_meth_inclif                    class   ClassExtendingFoo               Class                           #<Class:ClassExtendingFoo>
#
# --------------- ClassIncludingFoo
# meth_in_class                         obj     #<ClassIncludingFoo:0x000001020 ClassIncludingFoo
# self_meth_in_class                    class   ClassIncludingFoo               Class                           #<Class:ClassIncludingFoo>
# meth_in_sgtn_cl                       class   ClassIncludingFoo               Class                           #<Class:ClassIncludingFoo>
# self_meth_sgtn_cl                     sgtn_cl #<Class:ClassIncludingFoo>      Class
# module_meth_foo                       obj     #<ClassIncludingFoo:0x000001020 ClassIncludingFoo
# module_meth_inclif                    obj     #<ClassIncludingFoo:0x000001020 ClassIncludingFoo
#
# --------------- ClassInclFooInSgtnCl
# meth_in_class                         obj     #<ClassInclFooInSgtnCl:0x000001 ClassInclFooInSgtnCl
# self_meth_in_class                    class   ClassInclFooInSgtnCl            Class                           #<Class:ClassInclFooInSgtnCl>
# meth_in_sgtn_cl                       class   ClassInclFooInSgtnCl            Class                           #<Class:ClassInclFooInSgtnCl>
# self_meth_sgtn_cl                     sgtn_cl #<Class:ClassInclFooInSgtnCl>   Class
# module_meth_foo                       class   ClassInclFooInSgtnCl            Class                           #<Class:ClassInclFooInSgtnCl>
# module_meth_inclif                    class   ClassInclFooInSgtnCl            Class                           #<Class:ClassInclFooInSgtnCl>
#
# --------------- ClassExtFooInSgtnCl
# meth_in_class                         obj     #<ClassExtFooInSgtnCl:0x0000010 ClassExtFooInSgtnCl
# self_meth_in_class                    class   ClassExtFooInSgtnCl             Class                           #<Class:ClassExtFooInSgtnCl>
# meth_in_sgtn_cl                       class   ClassExtFooInSgtnCl             Class                           #<Class:ClassExtFooInSgtnCl>
# self_meth_sgtn_cl                     sgtn_cl #<Class:ClassExtFooInSgtnCl>    Class
# module_meth_foo                       sgtn_cl #<Class:ClassExtFooInSgtnCl>    Class
# module_meth_inclif                    sgtn_cl #<Class:ClassExtFooInSgtnCl>    Class


class SimpleClass
  class << self
    def self.self_meth_sgtn_cl() ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
    def meth_in_sgtn_cl()        ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
  end
  def self.self_meth_in_class()  ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
  def meth_in_class()            ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
end

module IncludedInFoo
  def self.module_self_inclif()  ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
  def module_meth_inclif()       ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
end

module ExtendedInFoo
  def self.module_self_extif()   ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
  def module_meth_extif()        ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
end

module Foo
  include IncludedInFoo
  extend  ExtendedInFoo
  def self.module_self_foo()     ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
  def module_meth_foo()          ; [self, self.class, ((self.is_a?(Class) && self.ancestors.first == self) ? self.singleton_class : nil)] ; end
end

class ClassExtendingFoo < SimpleClass
  extend Foo
  class << self
  end
end

class ClassIncludingFoo < SimpleClass
  include Foo
  class << self
  end
end

class ClassInclFooInSgtnCl < SimpleClass
  class << self
    include Foo
  end
end

class ClassExtFooInSgtnCl < SimpleClass
  class << self
    extend Foo
  end
end

def compare_methods(klass_a, klass_b)
  puts( "%-31s\tobj   \t%s" %  [klass_a.to_s[0..30], (klass_a.new.public_methods - Object.new.public_methods).inspect]) if klass_a.respond_to?(:new)
  puts( "%-31s\tklass \t%s" %  [klass_a.to_s[0..30], (klass_a.public_methods - klass_b.public_methods).inspect])
  puts( "%-31s\tsgtncl\t%s" %  [klass_a.to_s[0..30], (klass_a.singleton_class.public_methods - klass_b.singleton_class.public_methods).inspect])
  puts '---------------'
end

def show_anc_chain(klass_a)
  puts ['klass ', klass_a.ancestors                .reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
  puts ['sgtncl', klass_a.singleton_class.ancestors.reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
end

def show_method_selfness(klass_a)
  puts "\n", klass_a
  on = (klass_a.respond_to?(:new) ? { 'obj' => klass_a.new } : {})
  on['class']   = klass_a
  on['sgtn_cl'] = klass_a.singleton_class
  [
    :meth_in_class,
    :self_meth_in_class,
    :meth_in_sgtn_cl,
    :self_meth_sgtn_cl,

    :explicit_method_extif,
    :explicit_method_foo,
    :module_meth_extif,
    :module_meth_foo,
    :explicit_method_inclif,
    :module_meth_inclif,
    :module_self_extif,
    :module_self_foo,
    :module_self_inclif,
  ].each do |meth|
    on.each do |kind, obj|
      next unless obj.respond_to?(meth)
      puts( "%-31s\t%-7s\t%-31s\t%-31s\t%s" %  [meth, kind, obj.send(meth)].flatten.map{|x| x.to_s[0..30] } )
    end
  end
end

[Foo,
  ClassExtendingFoo, ClassIncludingFoo, ClassInclFooInSgtnCl,
  ClassExtFooInSgtnCl,
].each do |kl|
  show_method_selfness(kl)
  compare_methods(kl ,  Class)
end
