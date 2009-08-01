# Include hook code here
require 'serialist'
ActiveRecord::Base.send(:include, Serialist)