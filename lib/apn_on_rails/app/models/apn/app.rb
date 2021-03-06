module APN
  class Base < ActiveRecord::Base # :nodoc:

    def self.table_name # :nodoc:
      self.to_s.gsub("::", "_").tableize
    end

  end
end

class APN::App < APN::Base
  has_many :devices, :class_name => 'APN::Device', :dependent => :destroy
  has_many :notifications, :through => :devices, :dependent => :destroy
  has_many :unsent_notifications, :through => :devices
  validates_uniqueness_of :user_agent_string
    
  def cert
    if (RAILS_ENV == "production" || RAILS_ENV == "staging")
      env = "production"
    else
      env = "development"
    end
    puts "using certs"
    puts "#{user_agent_string.downcase}_#{env}.pem"
    return "#{user_agent_string.downcase}_#{env}.pem"
  end
  
  # Opens a connection to the Apple APN server and attempts to batch deliver
  # an Array of group notifications.
  # 
  # 
  # As each APN::GroupNotification is sent the <tt>sent_at</tt> column will be timestamped,
  # so as to not be sent again.
  # 
  def send_notifications
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.send_notifications_for_cert(self.cert, self.id)
  end
  
  def self.send_notifications
    apps = APN::App.all 
    apps.each do |app|
      app.send_notifications
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      send_notifications_for_cert(global_cert, nil)
    end
  end
  
  def self.send_notifications_for_cert(the_cert, app_id)
    #unless self.unsent_notifications.empty?
      if (app_id == nil)
        conditions = "app_id is null"
      else 
        conditions = ["app_id = ?", app_id]
      end
      begin
        APN::Connection.open_for_delivery({:cert => the_cert}) do |conn, sock|
          APN::Device.find_each(:conditions => conditions) do |dev|
            dev.unsent_notifications.each do |noty|
              conn.write(noty.message_for_sending)
              noty.sent_at = Time.now
              noty.save
            end
          end
        end
      rescue Exception => e
        puts e.message
      end
    #end   
  end
  
  # Retrieves a list of APN::Device instnces from Apple using
  # the <tt>devices</tt> method. It then checks to see if the
  # <tt>last_registered_at</tt> date of each APN::Device is
  # before the date that Apple says the device is no longer
  # accepting notifications then the device is deleted. Otherwise
  # it is assumed that the application has been re-installed
  # and is available for notifications.
  # 
  # This can be run from the following Rake task:
  #   $ rake apn:feedback:process
  def process_devices
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.process_devices_for_cert(self.cert)
  end # process_devices
  
  def self.process_devices
    apps = APN::App.all
    apps.each do |app|
      app.process_devices
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      APN::App.process_devices_for_cert(global_cert)
    end
  end
  
  def self.process_devices_for_cert(the_cert)
    puts "in APN::App.process_devices_for_cert"
    APN::Feedback.devices(the_cert).each do |device|
      if device.last_registered_at < device.feedback_at
        puts "device #{device.id} -> #{device.last_registered_at} < #{device.feedback_at}"
        device.destroy
      else 
        puts "device #{device.id} -> #{device.last_registered_at} not < #{device.feedback_at}"
      end
    end 
  end
    
end