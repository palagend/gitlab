require 'spec_helper'

describe MergeRequestsFinder do
  include ProjectForksHelper

  let(:user)  { create :user }
  let(:user2) { create :user }

  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let(:project1) { create(:project, :public, group: group) }
  let(:project2) { fork_project(project1, user) }
  let(:project3) do
    p = fork_project(project1, user)
    p.update!(archived: true)
    p
  end
  let(:project4) { create(:project, :public, group: subgroup) }

  let!(:merge_request1) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1) }
  let!(:merge_request2) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1, state: 'closed') }
  let!(:merge_request3) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project2) }
  let!(:merge_request4) { create(:merge_request, :simple, author: user, source_project: project3, target_project: project3) }
  let!(:merge_request5) { create(:merge_request, :simple, author: user, source_project: project4, target_project: project4) }

  before do
    project1.add_master(user)
    project2.add_developer(user)
    project3.add_developer(user)
    project2.add_developer(user2)
    project4.add_developer(user)
  end

  describe "#execute" do
    it 'filters by scope' do
      params = { scope: 'authored', state: 'opened' }
      merge_requests = described_class.new(user, params).execute
      expect(merge_requests.size).to eq(4)
    end

    it 'filters by project' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened' }
      merge_requests = described_class.new(user, params).execute
      expect(merge_requests.size).to eq(1)
    end

    it 'filters by group' do
      params = { group_id: group.id }

      merge_requests = described_class.new(user, params).execute

      expect(merge_requests.size).to eq(2)
    end

    it 'filters by group including subgroups', :nested_groups do
      params = { group_id: group.id, include_subgroups: true }

      merge_requests = described_class.new(user, params).execute

      expect(merge_requests.size).to eq(3)
    end

    it 'filters by non_archived' do
      params = { non_archived: true }
      merge_requests = described_class.new(user, params).execute
      expect(merge_requests.size).to eq(4)
    end

    it 'filters by iid' do
      params = { project_id: project1.id, iids: merge_request1.iid }

      merge_requests = described_class.new(user, params).execute

      expect(merge_requests).to contain_exactly(merge_request1)
    end

    context 'filtering by group milestone' do
      let!(:group) { create(:group, :public) }
      let(:group_milestone) { create(:milestone, group: group) }
      let!(:group_member) { create(:group_member, group: group, user: user) }
      let(:params) { { milestone_title: group_milestone.title } }

      before do
        project2.update(namespace: group)
        merge_request2.update(milestone: group_milestone)
        merge_request3.update(milestone: group_milestone)
      end

      it 'returns issues assigned to that group milestone' do
        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request2, merge_request3)
      end
    end

    context 'with created_after and created_before params' do
      let(:new_project) { create(:project, forked_from_project: project1) }

      let!(:new_merge_request) do
        create(:merge_request,
               :simple,
               author: user,
               created_at: 1.week.from_now,
               source_project: new_project,
               target_project: project1)
      end

      let!(:old_merge_request) do
        create(:merge_request,
               :simple,
               author: user,
               created_at: 1.week.ago,
               source_project: new_project,
               target_project: new_project)
      end

      before do
        new_project.add_master(user)
      end

      it 'filters by created_after' do
        params = { project_id: project1.id, created_after: new_merge_request.created_at }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(new_merge_request)
      end

      it 'filters by created_before' do
        params = { project_id: new_project.id, created_before: old_merge_request.created_at + 1.second }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(old_merge_request)
      end
    end
  end

  describe '#row_count', :request_store do
    it 'returns the number of rows for the default state' do
      finder = described_class.new(user)

      expect(finder.row_count).to eq(4)
    end

    it 'returns the number of rows for a given state' do
      finder = described_class.new(user, state: 'closed')

      expect(finder.row_count).to eq(1)
    end
  end
end
