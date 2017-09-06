module Groups
  module TransferErrorMessages
    def friendly_update_path_error
      "Oops, there was a problem transferring the group, this is not your fault. Please contact an admin."
    end

    def error_messages
      {
        already_a_root_group: "Group is already a root group.",
        database_not_supported: "Database is not supported.",
        group_with_same_path: "The parent group has a group with the same path.",
        missing_parent: "Please select a new parent for your group.",
        same_parent_as_current: "Group is already associated to the parent group.",
        invalid_policies: "You don't have enough permissions."
      }
    end

    def visibility_error_for(group, new_parent_group)
      "#{gitlab_visibility_level(group.visibility_level)} #{group.path} cannot be transferred because the parent visibility is #{gitlab_visibility_level(new_parent_group.visibility_level)}."
    end

    def gitlab_visibility_level(visibility_level)
      Gitlab::VisibilityLevel.string_level(visibility_level)
    end
  end
end
