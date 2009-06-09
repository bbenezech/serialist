# ActsAsSerializable
module ActsAsSerializable
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    
    attr_accessor :serialized_field

    def acts_as_serializable(field)
      
      @serialized_field = field

      include ActsAsSerializable::InstanceMethods
    end
    def inherited(subclass)
      super
      subclass.instance_variable_set("@serialized_field", @serialized_field)
    end
  end

  module InstanceMethods
    
    def initialize(*attr)
      super(*attr)
      update_attribute(self.class.serialized_field, Hash.new)
    end
    
    
    def method_missing(method, *args, &block)
      p self.class.to_s
      begin
        super
      rescue NoMethodError    
        case method.to_s.last
        when "?"
          self.send(self.class.serialized_field)[method.to_s[0..-2].to_sym] == (args && args.first || "true")
        when "="
          self.send(self.class.serialized_field)[method.to_s[0..-2].to_sym] = args.first if args
        else
          self.send(self.class.serialized_field)[method]
        end
      end
    end
  end
end


