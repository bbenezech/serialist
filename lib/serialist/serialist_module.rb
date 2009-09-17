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
          define_method field.to_s do 
            return nil unless (slug = self.send(serialist_field))
            slug[field.to_sym]
          end
          define_method field.to_s + "?" do |*param|
            return false unless (slug = self.send(serialist_field))
            if param.empty?
              ![nil, false, "false", :false].include?(slug[field.to_sym])
            else
              slug[field.to_sym] == param.first
            end
          end
          define_method field.to_s + "=" do |param|
            self.send(serialist_field.to_s + "=", Hash.new) unless self.send(serialist_field)
            self.send(serialist_field)[field.to_sym] = param
          end
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
    
    def attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!
      attributes.each do |k, v|
        unless k.include?("(") || respond_to?(:"#{k}=")
          self.class.send(:define_method, :"#{k}=") do |param|
            self.send(self.class.serialist_field.to_s + "=", Hash.new) unless self.send(self.class.serialist_field)
            self.send(self.class.serialist_field)[k.to_sym] = param
          end
        end
      end
      super
    end
    
    def method_missing(method, *args, &block)
      begin
        super
      rescue NoMethodError
        slug = self.send(self.class.serialist_field)
        case method.to_s.last
        when "?"
          slug && slug[method.to_s[0..-2].to_sym] == (args && args.first || "true")
          if args.empty?
            slug && ![nil, false, "false", :false].include?(slug[method.to_s[0..-2].to_sym])
          else
            slug && (slug[method.to_s[0..-2].to_sym] == args.first)
          end
        when "="
          self.send(slug.to_s + "=", Hash.new) unless slug
          self.send(self.class.serialist_field)[method.to_s[0..-2].to_sym] = args.first
        else
          slug && slug[method.to_sym]
        end
      end
    end
  end
end


