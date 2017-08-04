require 'spec_helper'

describe Milestone, 'Milestoneish' do
  let(:author) { build_stubbed(:user) }
  let(:assignee) { build_stubbed(:user) }
  let(:non_member) { build_stubbed(:user) }
  let(:member) { build_stubbed(:user) }
  let(:guest) { build_stubbed(:user) }
  let(:admin) { build_stubbed(:admin) }
  let(:project) { build_stubbed(:project, :public) }
  let(:milestone) { build_stubbed(:milestone, project: project) }
  let!(:issue) { build_stubbed(:issue, project: project, milestone: milestone) }
  let!(:security_issue_1) { build_stubbed(:issue, :confidential, project: project, author: author, milestone: milestone) }
  let!(:security_issue_2) { build_stubbed(:issue, :confidential, project: project, assignees: [assignee], milestone: milestone) }
  let!(:closed_issue_1) { build_stubbed(:issue, :closed, project: project, milestone: milestone) }
  let!(:closed_issue_2) { build_stubbed(:issue, :closed, project: project, milestone: milestone) }
  let!(:closed_security_issue_1) { build_stubbed(:issue, :confidential, :closed, project: project, author: author, milestone: milestone) }
  let!(:closed_security_issue_2) { build_stubbed(:issue, :confidential, :closed, project: project, assignees: [assignee], milestone: milestone) }
  let!(:closed_security_issue_3) { build_stubbed(:issue, :confidential, :closed, project: project, author: author, milestone: milestone) }
  let!(:closed_security_issue_4) { build_stubbed(:issue, :confidential, :closed, project: project, assignees: [assignee], milestone: milestone) }
  let!(:merge_request) { build_stubbed(:merge_request, source_project: project, target_project: project, milestone: milestone) }
  let(:label_1) { build_stubbed(:label, title: 'label_1', project: project, priority: 1) }
  let(:label_2) { build_stubbed(:label, title: 'label_2', project: project, priority: 2) }
  let(:label_3) { build_stubbed(:label, title: 'label_3', project: project) }

  before do
    project.team << [member, :developer]
    project.team << [guest, :guest]
  end

  describe '#sorted_issues' do
    it 'sorts issues by label priority' do
      issue.labels << label_1
      security_issue_1.labels << label_2
      closed_issue_1.labels << label_3

      issues = milestone.sorted_issues(member)

      expect(issues.first).to eq(issue)
      expect(issues.second).to eq(security_issue_1)
      expect(issues.third).not_to eq(closed_issue_1)
    end
  end

  describe '#sorted_merge_requests' do
    it 'sorts merge requests by label priority' do
      merge_request_1 = build_stubbed(:labeled_merge_request, labels: [label_2], source_project: project, source_branch: 'branch_1', milestone: milestone)
      merge_request_2 = build_stubbed(:labeled_merge_request, labels: [label_1], source_project: project, source_branch: 'branch_2', milestone: milestone)
      merge_request_3 = build_stubbed(:labeled_merge_request, labels: [label_3], source_project: project, source_branch: 'branch_3', milestone: milestone)

      merge_requests = milestone.sorted_merge_requests

      expect(merge_requests.first).to eq(merge_request_2)
      expect(merge_requests.second).to eq(merge_request_1)
      expect(merge_requests.third).to eq(merge_request_3)
    end
  end

  describe '#closed_items_count' do
    it 'does not count confidential issues for non project members' do
      expect(milestone.closed_items_count(non_member)).to eq 2
    end

    it 'does not count confidential issues for project members with guest role' do
      expect(milestone.closed_items_count(guest)).to eq 2
    end

    it 'counts confidential issues for author' do
      expect(milestone.closed_items_count(author)).to eq 4
    end

    it 'counts confidential issues for assignee' do
      expect(milestone.closed_items_count(assignee)).to eq 4
    end

    it 'counts confidential issues for project members' do
      expect(milestone.closed_items_count(member)).to eq 6
    end

    it 'counts all issues for admin' do
      expect(milestone.closed_items_count(admin)).to eq 6
    end
  end

  describe '#total_items_count' do
    it 'does not count confidential issues for non project members' do
      expect(milestone.total_items_count(non_member)).to eq 4
    end

    it 'does not count confidential issues for project members with guest role' do
      expect(milestone.total_items_count(guest)).to eq 4
    end

    it 'counts confidential issues for author' do
      expect(milestone.total_items_count(author)).to eq 7
    end

    it 'counts confidential issues for assignee' do
      expect(milestone.total_items_count(assignee)).to eq 7
    end

    it 'counts confidential issues for project members' do
      expect(milestone.total_items_count(member)).to eq 10
    end

    it 'counts all issues for admin' do
      expect(milestone.total_items_count(admin)).to eq 10
    end
  end

  describe '#complete?' do
    it 'returns false when has items opened' do
      expect(milestone.complete?(non_member)).to eq false
    end

    it 'returns true when all items are closed' do
      issue.close
      merge_request.close

      expect(milestone.complete?(non_member)).to eq true
    end
  end

  describe '#percent_complete' do
    it 'does not count confidential issues for non project members' do
      expect(milestone.percent_complete(non_member)).to eq 50
    end

    it 'does not count confidential issues for project members with guest role' do
      expect(milestone.percent_complete(guest)).to eq 50
    end

    it 'counts confidential issues for author' do
      expect(milestone.percent_complete(author)).to eq 57
    end

    it 'counts confidential issues for assignee' do
      expect(milestone.percent_complete(assignee)).to eq 57
    end

    it 'counts confidential issues for project members' do
      expect(milestone.percent_complete(member)).to eq 60
    end

    it 'counts confidential issues for admin' do
      expect(milestone.percent_complete(admin)).to eq 60
    end
  end

  describe '#remaining_days' do
    it 'shows 0 if no due date' do
      milestone = build_stubbed(:milestone)

      expect(milestone.remaining_days).to eq(0)
    end

    it 'shows 0 if expired' do
      milestone = build_stubbed(:milestone, due_date: 2.days.ago)

      expect(milestone.remaining_days).to eq(0)
    end

    it 'shows correct remaining days' do
      milestone = build_stubbed(:milestone, due_date: 2.days.from_now)

      expect(milestone.remaining_days).to eq(2)
    end
  end

  describe '#elapsed_days' do
    it 'shows 0 if no start_date set' do
      milestone = build_stubbed(:milestone)

      expect(milestone.elapsed_days).to eq(0)
    end

    it 'shows 0 if start_date is a future' do
      milestone = build_stubbed(:milestone, start_date: Time.now + 2.days)

      expect(milestone.elapsed_days).to eq(0)
    end

    it 'shows correct amount of days' do
      milestone = build_stubbed(:milestone, start_date: Time.now - 2.days)

      expect(milestone.elapsed_days).to eq(2)
    end
  end
end
