module Approvability
  class Approval < ActiveRecord::Base
    attr_accessible :approvable_id, :approvable_type, :approved_at, :notes, :rejected_at, :user_id, :reason_id, :verdict, :author_id

    attr_accessor :verdict

    belongs_to :approvable, polymorphic: true
    belongs_to :user
    belongs_to :owner, class_name: "Author"

    before_create :generate_token

    scope :for,       ->(object) {where(approvable_type: object)}
    scope :current,   -> { where(approved_at: nil, rejected_at: nil) }
    scope :approved,  -> { where("approved_at IS NOT NULL") }
    scope :rejected,  -> { where("rejected_at IS NOT NULL") }
    scope :historic,  -> { where("approved_at IS NOT NULL OR rejected_at IS NOT NULL") }
    scope :latest,    -> { order("created_at DESC") }
    scope :by_author, ->(author) { where(author_id: author) }

    # Generates a unique
    def generate_token(column="public_key", length = 64)
      begin
        self[column] = SecureRandom.urlsafe_base64 length
      end while Approvability::Approval.exists?(column => self[column])
    end

    # Returns the name of the kind of thing you are approving, e.g., Expert, Article, Product
    def object_name
      # Some jiggarypokery to turn Author (the name of the class) into Expert, the front-facing name of this object
      (self.approvable.class.name == "Author" ? "Expert" : self.approvable.class.name)
    end

    def accepted?
      !self.approved_at.nil? ? true : false
    end

    def rejected?
      !self.rejected_at.nil? ? true : false
    end

    # Returns +true+ if this Approval has been responded to in some way, either rejected or accepted.
    # @see {#accepted?} and {#rejected?}
    def actioned?
      accepted? == true || rejected? == true ? true : false
    end

    # Updates the timestamp to indicate the object has been accepted and updates the parent +approvable+ object to be active
    def accept!(user_id=nil)
      if self.approved_at.nil?
        self.activate_approvable
        Approvability::Notifier.confirm_approval(self).deliver # Send an email to the contributor
        self.update_attributes(rejected_at: nil, approved_at: Time.now, user_id: user_id)
      end
      self
    end

    # Updates the timestamp to indicate the object has been rejected and updates the parent +approvable+ object to be inactive
    def reject!(user_id=nil)
      if self.rejected_at.nil?
        self.deactivate_approvable
        self.update_attributes(rejected_at: Time.now, approved_at: nil, user_id: user_id)
      end
      self
    end

    def rollback_approval!
      if !self.rejected_at.nil? || !self.approved_at.nil?
        self.deactivate_approvable
        self.update_attributes(rejected_at: nil, approved_at: nil, user_id: nil)
      end
      self
    end

    # Processes this {Approval} updating the passed attributes and accepting or rejecting as we go
    # @param attrs [Hash] whatever you'd normally pass to the update_attributes() method
    # @return [Object] An instance of the updated {Approval} object
    # @todo Refector in order to avoid two update queries as {#act_on_verdict} also performs one
    def process(attrs, current_user)
      Approvability::Approval.act_on_verdict(attrs[:verdict], self, current_user)
      self.update_attributes(attrs)
    end

    # Changes the status of the approvable object
    def toggle_activity
      self.approvable.toggle! :active
    end

    def activate_approvable
      self.approvable.update_attributes!(active: true)
    end

    def deactivate_approvable
      self.approvable.update_attributes!(active: false)
    end

    # Checks for the presence of common identifiers such as a +name+ or +title+
    # on an approvable object like {Article} or a {Author} and returns whichever exists
    def common_name
      if defined?(self.approvable.name)
        self.approvable.name
      elsif defined?(approvable.title)
        self.approvable.title
      else
        "Object"
      end
    end

    # Returns a human readable name for what has just happened to the particular approval.
    # Requires that +attr_accessor :verdict+ was set, so this cannot be called on a Approval.find() object.
    def status_name
      case self.verdict
      when "1"
        "approved"
      when "0"
        "rejected"
      else
        "saved"
      end
    end

    ###
    # CLASS METHODS
    ###

    # Checks to see if this is a valid public_key has been passed for an approvable object
    def self.admin_preview_url_incorrect?(code, object)
      approval = Approvability::Approval.find_by_public_key(code)
      if !approval.nil? && approval.approvable_id == object.id && approval.approvable_type == object.class.name
        false
      else
        true
      end
    end

    # Given any approvable +object+, this method updates the {Approval} record and the +object+ record to respond
    # to a particular +verdict+ where the object is an approvalable author, article, etc.
    #
    # @param approval [Hash] params for the {Approval} passed through from the form_for(@approval) or similar
    # @param current_user [Object] the user signed in who will be held responsible for the approval
    # @todo Build the reject and delete functionality
    def self.process(approval=nil, current_user)
      if approval && approval[:id]
        Approvability::Approval.act_on_verdict(approval[:verdict], Approvability::Approval.find(approval[:id]), current_user)
      end
      # Return the verdict
      if approval[:verdict] == "1"
        true
      else
        false
      end
    end

    # Judges the appropreate case based on an intage for verdict
    # and executes the appropreate instance method to approve/deny this
    #
    # @param verdict [String] a numerical represenation of verdict 0, 1, or 2
    # @param approval [Object] the Approval record to update
    # @param current_user [Object] the {User} record to blame for this action
    def self.act_on_verdict(verdict, approval, current_user)
      case verdict
      when "1" # Approve
        approval.accept!(current_user.id)
      when "0" # Reject
        approval.reject!(current_user.id)
      when "2" # Reject and delete
        false # To do
      end
    end
  end # Class
end # Module