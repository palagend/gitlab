require 'rails_helper'

describe Groups::ConvertToRootService do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public, :nested) }
  let(:convert_to_root_service) { described_class.new(group, user) }

  describe "#execute" do
    context "when the user does not have enough permissions" do
      it "should return false" do
        expect(convert_to_root_service.execute).to be_falsy
      end

      it "should add an error to group" do
        convert_to_root_service.execute
        expect(convert_to_root_service.error).to eq("Transfer failed: You don't have enough permissions.")
      end
    end

    context "when the user is a root group" do
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }

      before do
        group.update_attribute(:parent_id, nil)
      end

      it "should return false" do
        expect(convert_to_root_service.execute).to be_falsy
      end

      it "should add an error to group" do
        convert_to_root_service.execute
        expect(convert_to_root_service.error).to eq("Transfer failed: Group is already a root group.")
      end
    end

    context "when the user does have enough permissions" do
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
      before do
        create_list(:project, 2, :repository, namespace: group)
        create_list(:group, 2, :public, parent: group)
        convert_to_root_service.execute
      end

      it "should update group attributes" do
        expect(group.parent).to be_nil
      end

      it "should transfer group's content to new root namespace" do
        group.projects.each do |project|
          expect(project.full_path).to eq("#{group.name}/#{project.name}")
        end
      end

      it "should transfer group's content to new directory" do
        group.projects.each do |project|
          full_path = project.repository_storage_path + '/' + project.full_path + '.git'
          expect(File.exist?(full_path)).to be_truthy
        end
      end
    end
  end
end
