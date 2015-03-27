module Approvability
  module ActsAsApprovability
  
    module Base
      def self.included(klass)
        klass.class_eval do
          extend Config
        end
      end
    
      module Config
        def acts_as_approvability
        
          # Flags that a contributor less than an administrator has submitted this
          attr_accessor :requires_approval

          # All Approvability models have polymorphic relationships with the Approval model
          has_many :approvals, as: :approvable, class_name: Approvability::Approval
          # Saves the approval automatically whenever models are flagged with {#requires_approval!} from a controller
          after_create :create_approval, if: :requires_approval
          accepts_nested_attributes_for :approvals

          # Uncomment this if for any reason you want to submit the approval flag via a form
          # Otherwise be content with using @approval_instnace.requires_approval! in the controller
          # attr_accessible :requires_approval

          attr_accessible :approvals_attributes
        
          include Approvability::ActsAsApprovability::Base::InstanceMethods
        end
      end
    
      module InstanceMethods
        # Sets the attr to true
        def requires_approval!
          self.requires_approval = true
          self.active = false
        end

        # Looks for the presence of an appropreate {Approval} record
        def awaiting_approval?
          self.approvals.current.length > 0 ? true : false
        end

        def requires_approval?
          requires_approval ? true : false
        end

        def has_approval?
          self.approvals.length > 0 ? true : false
        end

        # Pass params for the approvable object to update.
        # If they include an approval we'll process that as well
        def update_and_approve(new_params, user=nil)
          # Process the apporval if required
          unless new_params[:approvals_attributes].nil?
            accepted = Approval.process(new_params[:approvals_attributes]["0"], user)
            new_params[:active] = accepted
          end
          self.update_attributes(new_params)
        end
        
        # Scrubbs the histroy of approvals as well as the approvable record itself
        def destroy_and_clean_approvals(approvable)
          approvable.approvals.each do |a|
            a.destroy
          end
          approvable.destroy
        end

        def send_submission_alert
        
        end

        # Saves and associated {Approval} record
        def create_approval
          a = Approval.new(approvable_type: self.class.name, approvable_id: self.id)
          a.author_id = self.author_id unless self.class.name == "Author"
          a.save
          Approvability::Notifier.approval_required(self).deliver # Sends an email to the admin to allow them to approve this object
        end
      end
    end
    
  end
end

::ActiveRecord::Base.send :include, Approvability::ActsAsApprovability::Base