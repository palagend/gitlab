module Groups
  class ConvertToRootService < TransferService
    def execute
      with_transfer_error_handling do
        proceed_to_transfer
      end
    end

    private

    def proceed_to_transfer
      ensure_policies
      update_group_attributes
    end

    def ensure_policies
      raise_transfer_error(:invalid_policies) unless valid_policies?
      raise_transfer_error(:already_a_root_group) if root_group?
    end

    def valid_policies?
      can?(current_user, :admin_group, @group) &&
        can?(current_user, :create_group)
    end

    def root_group?
      !@group.has_parent?
    end

    def update_group_attributes
      @group.parent = nil
      @group.save!
    end
  end
end
