# ActsAsSerializable
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
            slug[field]
          end
          define_method field.to_s + "?" do |*param|
            return false unless (slug = self.send(serialist_field))
            if param.empty?
              ![nil, false, "false", :false].include?(slug[field])
            else
              slug[field] == param.first
            end
          end
          define_method field.to_s + "=" do |param|
            update_attribute(serialist_field, Hash.new) unless self.send(serialist_field)
            self.send(serialist_field)[field] = param
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
          update_attribute(self.class.serialist_field, Hash.new) unless slug
          self.send(self.class.serialist_field)[method.to_s[0..-2].to_sym] = args.first
        else
          slug && slug[method]
        end
      end
    end
  end
end


