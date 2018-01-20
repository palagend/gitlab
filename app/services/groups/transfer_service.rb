module Groups
  class TransferService < Groups::BaseService
    include TransferErrorMessages

    TransferError = Class.new(StandardError)
    attr_reader :error

    def initialize(group, user, params = {})
      super
      @error = nil
    end

    def execute(new_parent_group)
      @new_parent_group = new_parent_group
      ensure_allowed_transfer
      proceed_to_transfer

    rescue TransferError => e
      @error = "Transfer failed: " + e.message
      false
    rescue Gitlab::UpdatePathError
      @error = transferring_group_error
      false
    end

    private

    def proceed_to_transfer
      update_visibility
      update_group_attributes
    end

    def ensure_allowed_transfer
      raise_transfer_error(:group_is_already_root) if group_is_already_root
      raise_transfer_error(:database_not_supported) unless Group.supports_nested_groups?
      raise_transfer_error(:missing_parent) if @new_parent_group.blank?
      raise_transfer_error(:same_parent_as_current) if same_parent?
      raise_transfer_error(:invalid_policies) unless valid_policies?
      raise_transfer_error(:group_with_same_path) if group_with_same_path?
    end

    def group_is_already_root
      @new_parent_group.blank? && @group.parent.nil?
    end

    def same_parent?
      @new_parent_group.id == @group.parent_id
    end

    def valid_policies?
      can?(current_user, :admin_group, @group) &&
        can?(current_user, :create_subgroup, @new_parent_group)
    end

    def update_visibility
      @group.self_and_descendants.each do |subgroup|
        subgroup.update_column(:visibility_level, @new_parent_group.visibility_level)
      end
      @group.all_projects.update_all(visibility_level: @new_parent_group.visibility_level)
    end

    def update_group_attributes
      old_visibility_level = @group.visibility_level
      @group.visibility_level = new_visibility_level
      @group.parent = @new_parent_group
      @group.save!

    rescue ActiveRecord::RecordInvalid
      update_visibility(old_visibility_level)
    end

    def new_visibility_level
      @new_parent_group.visibility_level
    end

    def group_with_same_path?
      @new_parent_group.children.exists?(path: @group.path)
    end

    def raise_transfer_error(message)
      if message.is_a?(Symbol)
        raise TransferError, error_messages[message]
      else
        raise TransferError, message
      end
    end
  end
end
