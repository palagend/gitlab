Types::MergeRequestType = GraphQL::ObjectType.define do
  name 'MergeRequest'

  field :id, !types.ID
  field :iid, !types.ID
  field :title, types.String
  field :description, types.String
  field :state, types.String # TODO(nick.thomas): this should be an enum

  field :created_at, Types::TimeType
  field :updated_at, Types::TimeType

  # TODO(nick.thomas) check how loops are handled by graphql, e.g.:
  #   {
  #     project(path: 'foo/bar') {
  #       merge_requests(iid: 1) {
  #         project ...
  #       }
  #     }
  #  }
  # project is identical to target_project
  # field :source_project, -> { types.Project }
  # field :target_project, -> { types.Project }
  # field :project, -> { types.Project }

  field :source_project_id, types.Int
  field :target_project_id, types.Int

  field :source_branch, types.String
  field :target_branch, types.String

  field :work_in_progress, types.Boolean
  field :merge_when_pipeline_succeeds, types.Boolean

  field :merge_commit_sha, types.String # TODO(nick.thomas): types.SHA?
  field :user_notes_count, types.Int
  field :should_remove_source_branch, types.Boolean
  field :force_remove_source_branch, types.Boolean

  field :merge_status, types.String # TODO(nick.thomas): types.MergeStatus enum

=begin
  # TODO(nick.thomas)
  expose :web_url do |merge_request, options|
    Gitlab::UrlBuilder.build(merge_request)
  end

  # TODO(nick.thomas): These look like caching?
  expose :upvotes do |merge_request, options|
    if options[:issuable_metadata]
      options[:issuable_metadata][merge_request.id].upvotes
    else
      merge_request.upvotes
    end
  end

  expose :downvotes do |merge_request, options|
    if options[:issuable_metadata]
      options[:issuable_metadata][merge_request.id].downvotes
    else
      merge_request.downvotes
    end
  end

  expose :author, :assignee, using: Entities::UserBasic
  expose :labels do |merge_request, options|
    # Avoids an N+1 query since labels are preloaded
    merge_request.labels.map(&:title).sort
  end

  expose :milestone, using: Entities::Milestone

  expose :subscribed do |merge_request, options|
    merge_request.subscribed?(options[:current_user], options[:project])
  end

  expose :diff_head_sha, as: :sha
=end
end
