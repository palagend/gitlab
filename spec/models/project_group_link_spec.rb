require 'spec_helper'

describe ProjectGroupLink do
  describe "Associations" do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    let(:parent_group) { build_stubbed(:group) }
    let(:group) { build_stubbed(:group, parent: parent_group) }
    let(:project) { build_stubbed(:project, group: group) }
    let!(:project_group_link) { build_stubbed(:project_group_link, project: project) }

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_uniqueness_of(:group_id).scoped_to(:project_id).with_message(/already shared/) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:group_access) }

    it "doesn't allow a project to be shared with the group it is in" do
      project_group_link.group = group

      expect(project_group_link).not_to be_valid
    end

    it "doesn't allow a project to be shared with an ancestor of the group it is in", :nested_groups do
      project_group_link.group = parent_group

      expect(project_group_link).not_to be_valid
    end
  end

  describe "destroying a record", truncate: true do
    it "refreshes group users' authorized projects" do
      project     = build_stubbed(:project, :private)
      group       = build_stubbed(:group)
      reporter    = build_stubbed(:user)
      group_users = group.users

      group.add_reporter(reporter)
      project.project_group_links.create(group: group)
      group_users.each { |user| expect(user.authorized_projects).to include(project) }

      project.project_group_links.destroy_all
      group_users.each { |user| expect(user.authorized_projects).not_to include(project) }
    end
  end
end
