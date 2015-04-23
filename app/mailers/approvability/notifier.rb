module Approvability
  class Notifier < ActionMailer::Base
  
    default :from => "#{Approvability::Engine.configuration["default_from_email"]} <#{Approvability::Engine.configuration["default_from_name"]}>"
  
    def approval_required(object)
      get_config
      owner_email = Approvability::Engine.configuration["owner_email"]
      byline = ""
      if object.class.name != "Author"
        byline = " by #{object.author.name}"
      end
      @object = object
      @public_key = object.approvals.current.first.public_key
      @approval = object.approvals.current.first
      @author = (object.class.name == "Author" ? object : object.author)
      mail(to: owner_email, subject: "[Approval] New #{object.class.name.downcase}#{byline}")
    end
  
    def confirm_approval(approval)
      get_config
      @object = approval.approvable
      if approval.object_name == "Expert"
        @name = @object.user.name
        @type = "expert profile" 
        @titled = ""
        title = ""
        email = @object.user.email
      else  
        @name = @object.author.user.name
        @type = approval.object_name.downcase
        @titled = " entitled \"#{approval.common_name}\""
        title = " \"#{approval.common_name}\""
        email = @object.author.user.email
      end
      mail(to: email, subject: "Your #{@type}#{title} has been approved")
    end
    
    def get_config
      @owner = Approvability::Engine.configuration["owner_name"]
      @url = Approvability::Engine.configuration["website_url"]
      @img = Approvability::Engine.configuration["website_logo"]
      @business = Approvability::Engine.configuration["default_from_name"]
    end
  
  end
end