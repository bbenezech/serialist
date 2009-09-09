class SerialistGenerator < Rails::Generator::NamedBase
  attr_accessor :class_name, :migration_name, :migrated_table, :serialist_attribute
  
  def initialize(args, options = {})
    super
    @class_name = args[0]
    @migrated_table = args[1]
    @serialist_attribute = args[2]
  end
  
  def manifest
    @migration_name = file_name.camelize
    record do |m|
      # Migration creation
      m.migration_template "migrate/serialist_migration.rb.erb", "db/migrate", :migration_file_name => migration_name.underscore
    end
  end 
end
