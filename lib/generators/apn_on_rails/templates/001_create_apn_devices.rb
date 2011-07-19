class CreateApnDevices < ActiveRecord::Migration # :nodoc:
  def self.up
    create_table :apn_devices do |t|
      t.text :token, :size => 71, :null => false
      t.string :user_id, :null => false
      t.string :user_agent, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :apn_devices
  end
end
