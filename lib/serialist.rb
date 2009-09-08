# ActsAsSerializable
module Serialist
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_accessor :serialist_options
    attr_accessor :serialist_field

    def serialist(serialist_field, serialist_options)
      @serialist_field ||= serialist_field
      @serialist_options ||= []
      @serialist_options = (@serialist_options + serialist_options).uniq
      serialize(@serialist_field, Hash)

      @serialist_options.each do |field|
        puts "INCLUDE=#{self.instance_methods.include?(field.to_s)} FOR #{field.to_s}"
        
        raise Exception.new("Serialist ERROR: #{self.class.name} already has a #{field} method!") if self.instance_methods.include?(field.to_s)
        
        define_method field.to_s do 
          return nil unless self.send(serialist_field)
          self.send(serialist_field)[field]
        end
        
        define_method field.to_s + "?" do |*param|
          return false unless self.send(serialist_field)
          if param.empty?
            ![nil, false, "false", :false].include?(self.send(serialist_field)[field])
          else
            self.send(serialist_field)[field] == param.first
          end
        end
        
        define_method field.to_s + "=" do |param|
          update_attribute(serialist_field, Hash.new) unless self.send(serialist_field)
          self.send(serialist_field)[field] = param
        end
        
      end
    end
    
    def inherited(subclass)
      super
      subclass.instance_variable_set("@serialist_field", @serialist_field)
      subclass.instance_variable_set("@serialist_options", @serialist_options)
    end
  end
end


