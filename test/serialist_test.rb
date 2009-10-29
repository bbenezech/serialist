require 'test/unit'
 
require 'rubygems'
gem 'activerecord'
require 'active_record'
RAILS_ROOT = File.dirname(__FILE__)
$: << File.join(File.dirname(__FILE__), '../lib') 
require File.join(File.dirname(__FILE__), '../init')
 
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "acts_as_url.sqlite3")
 
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :serialisted_table, :force => true do |t|
    t.string :title
    t.string :type
    t.text :slug
    t.text :slug2
  end
end
ActiveRecord::Migration.verbose = true
 
class SerialistedLazy < ActiveRecord::Base
  def self.table_name 
    :serialisted_table
  end
  serialist :slug
  validates_presence_of :foo
end

class SerialistedDeclarative < ActiveRecord::Base
  def self.table_name 
    :serialisted_table
  end
  serialist :slug, [:foo, :bar]
  validates_presence_of :foo
end

class SubSerialistedLazy1 < SerialistedLazy
end
class SubSerialistedLazy2 < SerialistedLazy
  serialist :slug, [:foo, :bar]
end

class SubSerialistedDeclarative1 < SerialistedDeclarative
end
class SubSerialistedDeclarative2 < SerialistedDeclarative
  serialist :slug, [:foo, :baz]
end


class LazyRegressionTestClass < ActiveRecord::Base
  def self.table_name 
    :serialisted_table
  end
  validates_presence_of :title
  serialist :slug
  
  def title_fun
    title.reverse
  end
  
end

class DeclarativeRegressionTestClass < ActiveRecord::Base
  def self.table_name 
    :serialisted_table
  end
  validates_presence_of :title
  serialist :slug, [:foo, :bar]
  
  def title_fun
    title.reverse
  end
end


class SerialistTest < Test::Unit::TestCase
  # lazy
  def test_should_serialize_lazily
    @serialisted = SerialistedLazy.create!({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.slug[:foo], "foo"
    assert_equal @serialisted.foo, "foo"
    assert_equal @serialisted.foo?, true
    @serialisted.foo = "foo2"
    @serialisted.save
    @serialisted.reload
    assert_equal @serialisted.foo, "foo2"
    @serialisted.baz = "baz"
    @serialisted.save
    @serialisted.reload
    assert_equal @serialisted.baz, "baz"
    assert_equal @serialisted.baz?, true
    assert_equal @serialisted.baz?("baz"), true
    assert_equal @serialisted.baz?("bar"), false
    @serialisted.bar = nil
    @serialisted.save
    @serialisted.reload
    assert_equal @serialisted.bar?, false
  end
  
  # declarative
  def test_should_be_serialisted_declaratively
    @serialisted = SerialistedDeclarative.create!({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.slug[:foo], "foo"
    assert_equal @serialisted.foo, "foo"
    assert_equal @serialisted.foo?, true
    @serialisted.foo = "foo2"
    @serialisted.save
    @serialisted.reload
    assert_equal @serialisted.foo, "foo2"
    @serialisted.bar = nil
    @serialisted.save
    @serialisted.reload
    assert_equal @serialisted.bar?, false
  end
  
  def test_should_not_serialize_unknown_attributes_when_serialisted_declaratively
    assert_raise ActiveRecord::UnknownAttributeError do
       SerialistedDeclarative.create({:foo => "legit", :baz => "not legit"})
    end
    @serialisted = SerialistedDeclarative.create!({:foo => "legit"})
    assert_raise NoMethodError do
      @serialisted.baz = "not legit"
    end
  end
  
  # STI tests.
  
  # test {:foo, :bar} + {} => {:foo, :bar}
  def test_STI_classes_should_inherit_serialist_declarative_declaration
    @serialisted = SubSerialistedDeclarative1.create!({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.foo, "foo"
  end
  
  # test {:foo, :bar} + {:foo, :baz} => {:foo, :bar, :baz}
  def test_declarative_serialisted_STI_classes_should_inherit_serialist_declarative_declaration
    @serialisted = SubSerialistedDeclarative2.create!({:foo => "foo", :bar => "bar", :baz => "baz"})
    assert_equal @serialisted.foo, "foo"
    assert_equal @serialisted.bar, "bar"
    assert_equal @serialisted.baz, "baz"
    # but anyway :
    assert_raise ActiveRecord::UnknownAttributeError do
      SubSerialistedDeclarative2.create!({:catz => "dogz"})
    end
    assert_raise NoMethodError do
      @serialisted.catz
    end
  end
  
  # test {:all} + {} => {:all}
  def test_STI_classes_should_inherit_serialist_lazy_declaration
    @serialisted = SubSerialistedLazy1.create!({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.foo, "foo"
  end

  # test {:all} + {:foo, :bar} => {:all}
  def test_declarative_serialisted_STI_classes_should_not_override_serialist_lazy_declaration    
    @serialisted = SubSerialistedLazy2.create!({:foo => "foo", :bar => "bar", :baz => "baz"})
    assert_equal @serialisted.baz, "baz"
  end
  
  # non-regression test
  def test_mass_assignement_to_lazily_serialisted_should_not_create_record_if_record_is_invalid
    @serialisted = LazyRegressionTestClass.create({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.new_record?, true
    assert_nil @serialisted.id
  end
  
  def test_mass_assignement_to_declarative_serialisted_should_not_create_record_if_record_is_invalid
    @serialisted = DeclarativeRegressionTestClass.create({:foo => "foo", :bar => "bar"})
    assert_equal @serialisted.new_record?, true
    assert_nil @serialisted.id
  end
  
  def test_lazily_serialist_should_not_try_to_override_existing_methods_and_columns
    assert_raise ActiveRecord::UnknownAttributeError do
      LazyRegressionTestClass.create!({:foo => "foo", :bar => "bar", :title => "hoho", :title_fun => "haha"})
    end
    @serialisted = LazyRegressionTestClass.create!({:foo => "foo", :bar => "bar", :title => "hoho"})
    assert_nil @serialisted.slug[:title]
    assert_equal @serialisted.title, "hoho"
    assert_equal @serialisted.title_fun, "ohoh"
  end
end