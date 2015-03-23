class CreateApprovabilityApprovals < ActiveRecord::Migration
  def change
    create_table :approvability_approvals do |t|
      t.string :approvable_type
      t.integer :approvable_id
      t.datetime :approved_at
      t.text :notes
      t.integer :user_id
      t.integer :reason_id
      t.datetime :rejected_at
      t.timestamps
    end
  end
end
