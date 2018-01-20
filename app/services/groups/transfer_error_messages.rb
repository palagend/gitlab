module Groups
  module TransferErrorMessages
    def transferring_group_error
      'There was a problem transferring the group, this is not your fault. Please contact support.'
    end

    def error_messages
      {
        already_a_root_group: 'Group is already a root group.',
        database_not_supported: 'Database is not supported.',
        group_with_same_path: 'The parent group has a group with the same path.',
        missing_parent: 'Please select a new parent for your group.',
        same_parent_as_current: 'Group is already associated to the parent group.',
        invalid_policies: "You don't have enough permissions.",
        group_is_already_root: 'Group is already a root group.'
      }
    end
  end
end
