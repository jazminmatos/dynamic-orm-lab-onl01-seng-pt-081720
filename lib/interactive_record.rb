require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
    def self.table_name #returns the class' table name
        self.to_s.downcase.pluralize
    end

    def self.column_names #queries a table for its column names
        DB[:conn].results_as_hash = true #allows the next line to return as hash

        sql = "PRAGMA table_info(#{table_name})" #uses table_name method

        table_info = DB[:conn].execute(sql)
        column_names = [] #set empty array for which to store column names

        table_info.each do |column| #iterates over hash to retrieve column names
            column_names << column["name"]
        end

        column_names.compact #returns an array of the column names
    end

    def initialize(options = {}) #argument of options defaults to empty hash
        options.each do |property, value|
            #binding.pry
            self.send("#{property}=", value) #interpolates the name of each hash key as a method that we set equal to that key's value
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []

        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end

        values.join(", ")
    end

    def save
        sql = <<-SQL 
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) 
            VALUES (#{values_for_insert})
            SQL

        DB[:conn].execute(sql)
        
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        attribute_key = attribute.keys.join()
        attribute_value = attribute.values.first

    sql =<<-SQL
        SELECT * FROM #{self.table_name}
        WHERE #{attribute_key} = "#{attribute_value}"
        LIMIT 1
        SQL
        
        row = DB[:conn].execute(sql)
    end
end