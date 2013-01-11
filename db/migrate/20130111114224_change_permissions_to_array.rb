class ChangePermissionsToArray < Mongoid::Migration
  class User
    include Mongoid::Document
    include Mongoid::Timestamps

    field "permissions"

    def self.collection_name
      "panopticon_users"
    end
  end

  def self.up
    User.all.each do |user|
      if user.permissions.is_a?(Hash)
        user.permissions = user.permissions["Panopticon"]
        user.save!
      end
    end
  end

  def self.down
    User.all.each do |user|
      unless user.permissions.nil?
        user.permissions = { "Panopticon" => user.permissions }
        user.save!
      end
    end
  end
end