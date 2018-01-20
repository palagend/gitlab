require 'rails_helper'

describe Groups::TransferService do
  let(:user) { create(:user) }
  let(:new_parent_group) { create(:group, :public) }
  let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
  let(:transfer_service) { described_class.new(group, user) }

  shared_examples 'ensuring allowed transfer for a group' do
    context 'with other database than PostgreSQL' do
      before do
        allow(Group).to receive(:supports_nested_groups?).and_return(false)
      end

      it 'should return false' do
        expect(transfer_service.execute(new_parent_group)).to be_falsy
      end

      it 'should add an error on group' do
        transfer_service.execute(new_parent_group)
        expect(transfer_service.error).to eq('Transfer failed: Database is not supported.')
      end
    end

    context "when there's an exception on Gitlab shell directories" do
      let(:new_parent_group) { create(:group, :public) }

      before do
        allow_any_instance_of(described_class).to receive(:update_group_attributes).and_raise(Gitlab::UpdatePathError)
        create(:group_member, :owner, group: new_parent_group, user: user)
      end

      it 'should return false' do
        expect(transfer_service.execute(new_parent_group)).to be_falsy
      end

      it 'should add an error on group' do
        transfer_service.execute(new_parent_group)
        expect(transfer_service.error).to eq('There was a problem transferring the group, this is not your fault. Please contact support.')
      end
    end
  end

  describe '#execute' do
    context 'when transforming a group into a root group' do
      let(:group) { create(:group, :public) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the group is already a root group' do
        it 'should add an error on group' do
          transfer_service.execute('')
          expect(transfer_service.error).to eq('Transfer failed: Group is already a root group.')
        end

        context 'when the user does not have the right policies' do
        end

        context 'when the group is a subgroup' do
        end
      end
    end

    context 'when transferring a root group into a subgroup' do
      let(:group) { create(:group, :public) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the user does not have the right policies'

      context 'when the parent has a group with the same path'

      context 'when the root group is allowed to be transferred'
    end

    context 'when transferring a subgroup into another group' do
      let(:group) { create(:group, :public, :nested) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the new parent group is the same as the previous parent group' do
        let(:group) { create(:group, :public, :nested, parent: new_parent_group) }

        it 'should return false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'should add an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: Group is already associated to the parent group.')
        end
      end

      context 'when the user does not have the right policies' do
        let!(:group_member) { create(:group_member, :guest, group: group, user: user) }

        it "should return false" do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it "should add an error on group" do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq("Transfer failed: You don't have enough permissions.")
        end
      end

      context 'with no parent_group given and the group is a subgroup' do
        it 'should return false' do
          expect(transfer_service.execute(nil)).to be_falsy
        end

        it 'should add an error on group' do
          transfer_service.execute(nil)
          expect(transfer_service.error).to eq('Transfer failed: Please select a new parent for your group.')
        end
      end

      context 'when the parent has a group with the same path' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          group.update_attribute(:path, "not-unique")
          create(:group, path: "not-unique", parent: new_parent_group)
        end

        it 'should return false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'should add an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: The parent group has a group with the same path.')
        end
      end

      context 'when the group is allowed to be transferred' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'should update visibility for the group based on the parent group' do
          expect(group.visibility_level).to eq(new_parent_group.visibility_level)
        end

        it 'should update parent group to the new parent ' do
          expect(group.parent).to eq(new_parent_group)
        end

        it 'should return the group as children of the new parent' do
          expect(new_parent_group.children.count).to eq(1)
          expect(new_parent_group.children.first).to eq(group)
        end
      end

      context 'when transferring a group with group descendants' do
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }

        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'should update subgroups visibility' do
          group.children.each do |subgroup|
            expect(subgroup.visibility_level).to eq(new_parent_group.visibility_level)
          end
        end

        it 'should update subgroups path' do
          new_parent_path = new_parent_group.path
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{new_parent_path}/#{group.path}/#{subgroup.path}")
          end
        end
      end

      context 'when transferring a group with project descendants' do
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:project2) { create(:project, :repository, :internal, namespace: group) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'should update projects visibility' do
          group.projects.each do |project|
            expect(project.visibility_level).to eq(new_parent_group.visibility_level)
          end
        end

        it 'should update projects path' do
          new_parent_path = new_parent_group.path
          group.projects.each do |project|
            expect(project.full_path).to eq("#{new_parent_path}/#{group.path}/#{project.name}")
          end
        end
      end

      context 'when transferring a group with group & project descendants' do
      end
    end

    context "with valid policies (to be deleted soon)" do
      before do
        create_list(:project, 2, :repository, namespace: group)
        create_list(:project, 2, :repository, namespace: new_parent_group)
        create_list(:group, 2, :public, parent: group)
        create(:group_member, :owner, group: new_parent_group, user: user)
        transfer_service.execute(new_parent_group)
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
        transfer_service.execute(new_parent_group)
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
        transfer_service.execute(new_parent_group)
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

