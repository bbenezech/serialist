# Include hook code here
require 'acts_as_serializable'
ActiveRecord::Base.send(:include, ActsAsSerializable)