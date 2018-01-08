require 'rails_helper'

describe Groups::ConvertToSubgroupService do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public, :nested) }
  let(:new_parent_group) { create(:group, :public) }
  let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
  let(:convert_to_subgroup_service) { described_class.new(group, user) }
  let(:previous_parent) { create(:group, :public) }

  describe "#execute" do
    context "with other database than postgresql" do
      before do
        allow(Group).to receive(:supports_nested_groups?).and_return(false)
      end

      it "should return false" do
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq('Transfer failed: Database is not supported.')
      end
    end

    context "when the new parent group is the same as the previous parent group" do
      it "should return false" do
        new_parent_group = group.parent
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        new_parent_group = group.parent
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq('Transfer failed: Group is already associated to the parent group.')
      end
    end

    context "when the user does not have the right policies" do
      let!(:group_member) { create(:group_member, :guest, group: group, user: user) }

      it "should return false" do
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq("Transfer failed: You don't have enough permissions.")
      end
    end

    context "with no parent_group given" do
      it "should return false" do
        expect(convert_to_subgroup_service.execute(nil)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(nil)
        expect(convert_to_subgroup_service.error).to eq('Transfer failed: Please select a new parent for your group.')
      end
    end

    context "when the parent has higher visibility" do
      let(:group) { create(:group, :public, :nested) }
      let(:new_parent_group) { create(:group, :private) }
      let(:convert_to_subgroup_service) { described_class.new(group, user) }

      before do
        create(:group_member, :owner, group: new_parent_group, user: user)
      end

      it "should return false" do
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq("Transfer failed: public #{group.path} cannot be transferred because the parent visibility is private.")
      end
    end

    context "when the parent has a group with the same name" do
      before do
        create(:group_member, :owner, group: new_parent_group, user: user)
        group.update_attribute(:path, "not-unique")
        create(:group, path: "not-unique", parent: new_parent_group)
      end

      it "should return false" do
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq('Transfer failed: The parent group has a group with the same path.')
      end
    end

    context "when there's an exception on Gitlab shell directories" do
      let(:new_parent_group) { create(:group, :public) }

      before do
        allow_any_instance_of(described_class).to receive(:update_group_attributes).and_raise(Gitlab::UpdatePathError)
        create(:group_member, :owner, group: new_parent_group, user: user)
      end

      it "should return false" do
        expect(convert_to_subgroup_service.execute(new_parent_group)).to be_falsy
      end

      it "should add an error on group" do
        convert_to_subgroup_service.execute(new_parent_group)
        expect(convert_to_subgroup_service.error).to eq('Oops, there was a problem transferring the group, this is not your fault. Please contact an admin.')
      end
    end

    context "with valid policies" do
      let(:new_parent_group) { create(:group, :public) }

      before do
        create_list(:project, 2, :repository, namespace: group)
        create_list(:project, 2, :repository, namespace: new_parent_group)
        create_list(:group, 2, :public, parent: group)
        create(:group_member, :owner, group: new_parent_group, user: user)
        convert_to_subgroup_service.execute(new_parent_group)
      end

      it "should update visibility for the group based on the parent group" do
        expect(group.visibility_level).to eq(new_parent_group.visibility_level)
      end

      it "should update visibility for the group projects" do
        group.projects.each do |project|
          expect(project.visibility_level).to eq(new_parent_group.visibility_level)
        end
      end

      it "should update visibility for the group children" do
        group.children.each do |g|
          expect(g.visibility_level).to eq(new_parent_group.visibility_level)
        end
      end

      it "should update visibility for the projects of the group children" do
        group.children.each do |g|
          g.projects.each do |project|
            expect(project.visibility_level).to eq(new_parent_group.visibility_level)
          end
        end
      end

      it "should set new parent group as the parent" do
        expect(group.parent).to eq(new_parent_group)
      end

      it "should transfer the projects to the new namespace" do
        pending
        group.projects.each do |project|
          expect(project.full_path).to eq("#{new_parent_group.name}/#{group.name}/#{project.name}")
        end
      end

      it "should transfer group's content to new directory" do
        group.projects.each do |project|
          full_path = project.repository_storage_path + '/' + project.full_path + '.git'
          expect(File.exist?(full_path)).to be_truthy
        end
      end
    end

    context "when the parent group does not have a directory created" do
      let(:new_parent_group) { create(:group, :public) }

      before do
        allow(described_class).to receive(:gitlab_storage_path).and_return(Rails.root.to_s + '/' + Gitlab.config.repositories["storages"]["default"]["path"])
        create_list(:project, 2, :repository, namespace: group)
        create_list(:group, 2, :public, parent: group)
        create(:group_member, :owner, group: new_parent_group, user: user)
        convert_to_subgroup_service.execute(new_parent_group)
      end

      it "should set the new parent group as the parent" do
        expect(group.parent).to eq(new_parent_group)
      end
    end

    context "when updating the group and this one is invalid" do
      let(:group) { create(:group, :private, :nested) }

      let(:new_parent_group) { create(:group, :public) }

      before do
        create_list(:project, 2, :repository, :private, namespace: group)
        create(:group_member, :owner, group: new_parent_group, user: user)
        @old_visibility = group.visibility_level
        allow(group).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(group))
        convert_to_subgroup_service.execute(new_parent_group)
        group.reload
      end

      it "should not update visilibility level for the group" do
        expect(group.visibility_level).to eq(@old_visibility)
      end

      it "should restore the old visibility level for group's children" do
        group.projects.each do |project|
          expect(project.visibility_level).to eq(@old_visibility)
        end
      end
    end
  end
end
