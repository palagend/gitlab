module Groups
  class ConvertToSubgroupService < TransferService
    def execute(new_parent_group)
      @new_parent_group = new_parent_group

      with_transfer_error_handling do
        proceed_to_transfer
      end
    end

    private

    def proceed_to_transfer
      ensure_allowed_transfer
      update_visibility(new_visibility_level)
      update_group_attributes
    end

    def ensure_allowed_transfer
      raise_transfer_error(:database_not_supported) unless Group.supports_nested_groups?
      raise_transfer_error(:missing_parent) if @new_parent_group.blank?
      raise_transfer_error(:same_parent_as_current) if same_parent?
      raise_transfer_error(:invalid_policies) unless valid_policies?
      raise_transfer_error(:group_with_same_path) if group_with_same_path?
      raise_transfer_error(visibility_error_for(@group, @new_parent_group)) unless allowed_visibility?
    end

    def same_parent?
      @new_parent_group.id == @group.parent_id
    end

    def valid_policies?
      can?(current_user, :admin_group, @group) &&
        can?(current_user, :create_subgroup, @new_parent_group)
    end

    def allowed_visibility?
      @group.visibility_level <= new_visibility_level
    end

    def update_visibility(visibility_level)
      @group.projects.update_all(visibility_level: visibility_level)
      @group.self_and_descendants.update_all(visibility_level: visibility_level)
      @group.all_projects.update_all(visibility_level: visibility_level)
    end

    def update_group_attributes
      old_visibility_level = @group.visibility_level
      @group.visibility_level = new_visibility_level
      @group.parent = @new_parent_group
      @group.save!
    rescue ActiveRecord::RecordInvalid
      update_visibility(old_visibility_level)
    end

    def group_with_same_path?
      @new_parent_group.children.exists?(path: @group.path)
    end

    def new_visibility_level
      @new_parent_group.visibility_level
    end
  end
end
