module Serialist
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_accessor :serialist_options
    attr_accessor :serialist_field

    def serialist(serialist_field, serialist_options = [])
      @serialist_field ||= serialist_field
      @serialist_options ||= []
      @serialist_options = (@serialist_options + serialist_options).uniq
      serialize(@serialist_field, Hash)
      
      if serialist_options.empty?
        include Serialist::InstanceMethods
      else
        @serialist_options.each do |field|
          cols = self.columns.map{|c|c.name.to_s}
          raise Exception.new("Column #{field} already exist for #{self.name}") if cols.include?(field.to_s)
          define_access_methods(field)
        end
      end
    end
    
    def define_access_methods(field)
      serialist_field = self.serialist_field
      define_method field.to_s do 
        return nil unless (slug = self.send(serialist_field))
        slug[field.to_sym]
      end
      define_method field.to_s + "?" do |*param|
        return false unless (slug = self.send(serialist_field))
        if param.empty?
          ![nil, false, "false", :false, "0"].include?(slug[field.to_sym])
        else
          slug[field.to_sym] == param.first
        end
      end
      define_method field.to_s + "=" do |param|
        self.send(serialist_field.to_s + "=", Hash.new) unless self.send(serialist_field)
        self.send(serialist_field)[field.to_sym] = param
      end
    end
    
    def inherited(subclass)
      super
      subclass.instance_variable_set("@serialist_field", @serialist_field)
      subclass.instance_variable_set("@serialist_options", @serialist_options)
    end
  end
  
  module InstanceMethods
    def attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil? 
      attributes = new_attributes.dup
      attributes.stringify_keys!
      attributes.each do |k, v|
        unless k.include?("(") || respond_to?(k)
          self.class.define_access_methods(k)
        end
      end
      super
    end
    
    def method_missing(method, *args, &block)
      begin
        super
      rescue NoMethodError
        self.class.define_access_methods(method.to_s.chomp("=").chomp("?"))
        self.send(method, *args, &block)
      end
    end
  end
end


