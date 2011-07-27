namespace :apn do
  
  namespace :notifications do
    
    desc "Deliver all unsent APN notifications."
    task :deliver => [:environment] do
      for app in APN::App.all
        app.send_notifications
      end
    end
    
  end # notifications
  
  namespace :notifications do
    
    desc "Deliver all unsent APN notifications."
    task :deliver_constantly => [:environment] do
      while true do

        puts "sending"
        app.send_notifications
        sleep 2
      end
      
    end
    
  end # notifications
  
  namespace :feedback do
    
    desc "Process all devices that have feedback from APN."
    task :process => [:environment] do
      APN::Feedback.process_devices
    end
    
  end
  
end # apn