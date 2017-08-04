require 'spec_helper'

describe 'CycleAnalytics#production' do
  extend CycleAnalyticsHelpers::TestGeneration

  let(:project) { build_stubbed(:project, :repository) }
  let(:from_date) { 10.days.ago }
  let(:user) { build_stubbed(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(
    phase: :production,
    data_fn: -> (context) { { issue: context.build(:issue, project: context.project) } },
    start_time_conditions: [["issue is created", -> (context, data) { data[:issue].save }]],
    before_end_fn: lambda do |context, data|
      context.create_merge_request_closing_issue(data[:issue])
      context.merge_merge_requests_closing_issue(data[:issue])
    end,
    end_time_conditions:
      [["merge request that closes issue is deployed to production", -> (context, data) { context.deploy_master }],
       ["production deploy happens after merge request is merged (along with other changes)",
        lambda do |context, data|
          # Make other changes on master
          sha = context.project.repository.create_file(
            context.user,
            context.generate(:branch),
            'content',
            message: 'commit message',
            branch_name: 'master')
          context.project.repository.commit(sha)

          context.deploy_master
        end]])

  context "when a regular merge request (that doesn't close the issue) is merged and deployed" do
    it "returns nil" do
      merge_request = build_stubbed(:merge_request)
      MergeRequests::MergeService.new(project, user).execute(merge_request)
      deploy_master

      expect(subject[:production].median).to be_nil
    end
  end

  context "when the deployment happens to a non-production environment" do
    it "returns nil" do
      issue = build_stubbed(:issue, project: project)
      merge_request = create_merge_request_closing_issue(issue)
      MergeRequests::MergeService.new(project, user).execute(merge_request)
      deploy_master(environment: 'staging')

      expect(subject[:production].median).to be_nil
    end
  end
end
