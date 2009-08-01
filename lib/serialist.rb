# ActsAsSerializable
module Serialist
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    
    attr_accessor :serialization_field

    def serialist(field)
      
      @serialization_field = field

      include ActsAsSerializable::InstanceMethods
    end
    def inherited(subclass)
      super
      subclass.instance_variable_set("@serialization_field", @serialization_field)
    end
  end

  module InstanceMethods
    
    def initialize
      super
      update_attribute(self.class.serialization_field, Hash.new)
    end

    def method_missing(method, *args, &block)
      begin
        super
      rescue NoMethodError    
        case method.to_s.last
        when "?"
          self.send(self.class.serialization_field)[method.to_s[0..-2].to_sym] == (args && args.first || "true")
        when "="
          self.send(self.class.serialization_field)[method.to_s[0..-2].to_sym] = args.first if args
        else
          self.send(self.class.serialization_field)[method]
        end
      end
    end
  end
end


