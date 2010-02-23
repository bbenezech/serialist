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
          self.send(serialist_field)[method[0..-2].to_sym] = param
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
end


