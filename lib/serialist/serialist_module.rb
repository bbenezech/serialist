module Serialist
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_accessor :serialist_options
    attr_accessor :serialist_field

    def serialist(serialist_field, serialist_options = [])
      @serialist_field = serialist_field
      @serialist_options = serialist_options
      serialize(@serialist_field, Hash)
      include Serialist::DirtyAdditions
      class_eval do
        unless method_defined?(:changes)
          def changes(meth, *args, &block); super; end
        end
        alias_method :old_changes, :changes
        alias_method :changes, :serialist_changes
      end
      
      if serialist_options.empty?
        # catch-all mode
        include Serialist::InstanceMethods
        class_eval do
          # alias method chaining
          unless method_defined? :method_missing
            def method_missing(meth, *args, &block); super; end
          end
          alias_method :old_method_missing, :method_missing
          alias_method :method_missing, :serialist_method_missing
          unless method_defined?(:attributes=)
            def attributes=(meth, *args, &block); super; end
          end
          alias_method :old_attributes=, :attributes=
          alias_method :attributes=, :serialist_attributes=
        end
      else
        @serialist_options.each do |field|
          cols = self.columns.map{|c|c.name.to_s}
          raise Exception.new("Column #{field} already exist for #{self.name}") if cols.include?(field.to_s)
          define_access_method(field.to_s)
          define_access_method(field.to_s + "?")
          define_access_method(field.to_s + "=")
        end
      end
    end
    
    def define_access_method(method)
      serialist_field = self.serialist_field
      case method.last
      when "?"
        define_method method do |*param|
          return false unless (slug = self.send(serialist_field))
          if param.empty?
            ![nil, false, "false", :false, "0"].include?(slug[method[0..-2].to_sym])
          else
            slug[method[0..-2].to_sym] == param.first
          end
        end
      when "="
        define_method method do |param|
          self.send(serialist_field.to_s + "=", Hash.new) unless self.send(serialist_field)
          # needed to get dirty
          slug = self.send(serialist_field).clone
          slug[method[0..-2].to_sym] = param
          write_attribute(serialist_field.to_s, slug)
        end
      else
        define_method method do 
          return nil unless (slug = self.send(serialist_field))
          method.ends_with?("_id") ? slug[method.to_sym].to_i : slug[method.to_sym]
        end
      end
    end
    
    def inherited(subclass)
      super
      subclass.instance_variable_set("@serialist_field", @serialist_field)
      subclass.instance_variable_set("@serialist_options", @serialist_options)
    end
  end
  
  module InstanceMethods
    
    # needed because AR checks with respond_to when doing mass assignment.
    def serialist_attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil? 
      attributes = new_attributes.dup
      attributes.stringify_keys!
      attributes.each do |k, v|
        unless k.include?("(")
          self.class.define_access_method(k + "=") unless respond_to?("#{k}=")  # for mass-affectation
          self.class.define_access_method(k) unless respond_to?(k)              # for validation
        end
      end
      self.send(:old_attributes=, new_attributes, guard_protected_attributes = true)
    end
    
    def serialist_method_missing(method, *args, &block)
      begin
        old_method_missing(method, *args, &block)
      rescue NoMethodError
        self.class.define_access_method(method.to_s)
        self.send(method, *args, &block)
      end
    end
  end
  
  module DirtyAdditions
    def serialist_changes
      full_changes = self.old_changes
      unless (slug = full_changes.delete(self.class.serialist_field.to_s)).blank?
        ((slug[0].try(:keys) || []) + (slug[1].try(:keys) || [])).uniq.each do |serialized_key| 
          attr_change = [(slug[0].try(:fetch, serialized_key) rescue nil), (slug[1].try(:fetch, serialized_key) rescue nil)]
          full_changes[serialized_key.to_s] = attr_change if attr_change[0] != attr_change[1]
        end
      end
      full_changes
    end
  end
end


