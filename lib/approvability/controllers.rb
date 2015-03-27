module Approvability
  module Controllers
    
    def approvable_index(parent)
      @approvals = Approval.for(parent).current
      @recently_approved = Approval.for(parent).historic.order("approved_at DESC").limit(5)
    end
    
  end
end