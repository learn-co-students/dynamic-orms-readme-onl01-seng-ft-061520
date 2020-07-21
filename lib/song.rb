require_relative "../config/environment.rb"
require 'active_support/inflector'
# NOTE: Above inflector provides the pluralize method inside the self.table_name method


class Song

  # Converts Class name to the database Table name (Song => songs)
  def self.table_name
    self.to_s.downcase.pluralize
  end


  # Collects the column names (of the specified database table) into an array
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
    # .compact removes any nil values from the array collected
  end


  # Iterates over the array of stored column names and converts each column name to a symbol (to_sym) and assigns it to attr_accessor
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end


  # Builds a generic initialize method that's flexible in number of parameters given
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

####################### BEGIN DEPENDENT METHODS BEGIN #######################

  # save is an instance method so we use self.class in the 3 _insert methods to access class methods
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end


  # send is used to get the value stored in the column name
  # unless is used to bypass the value of the missing id column name because it will be auto assigned
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end


  # Remove the id because it will be auto assigned
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

####################### END DEPENDENT METHODS END #######################


  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



