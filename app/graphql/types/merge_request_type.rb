Types::MergeRequestType = GraphQL::ObjectType.define do
  name 'MergeRequest'

  field :id, !types.ID
  field :iid, !types.ID
  field :title, types.String
  field :description, types.String
  field :state, types.String

  field :created_at, Types::TimeType
  field :updated_at, Types::TimeType

  field :source_project, -> { Types::ProjectType }
  field :target_project, -> { Types::ProjectType }

  # Alias for target_project
  field :project, -> { Types::ProjectType }

  field :source_project_id, types.Int
  field :target_project_id, types.Int
  field :project_id, types.Int

  field :source_branch, types.String
  field :target_branch, types.String

  field :work_in_progress, types.Boolean, property: :work_in_progress?
  field :merge_when_pipeline_succeeds, types.Boolean

  field :sha, types.String, property: :diff_head_sha
  field :merge_commit_sha, types.String

  field :user_notes_count, types.Int
  field :should_remove_source_branch, types.Boolean, property: :should_remove_source_branch?
  field :force_remove_source_branch, types.Boolean, property: :force_remove_source_branch?

  field :merge_status, types.String

  field :web_url, types.String do
    resolve ->(merge_request, args, ctx) { Gitlab::UrlBuilder.build(merge_request) }
  end

  # TODO(nick.thomas): These two seemed to have some caching involved, like:
  #
  #   if options[:issuable_metadata]
  #     options[:issuable_metadata][merge_request.id].upvotes
  #    else
  #      merge_request.upvotes
  #    end
  #
  # Still necessary?
  field :upvotes, types.Int
  field :downvotes, types.Int

  # TODO(nick.thomas): associations we don't support yet
  # expose :author, :assignee, using: Entities::UserBasic
  # expose :labels do |merge_request, options|
  #   # Avoids an N+1 query since labels are preloaded
  #   merge_request.labels.map(&:title).sort
  # end
  # expose :milestone, using: Entities::Milestone

  field :subscribed, types.Boolean do
    resolve ->(merge_request, args, ctx) do
      merge_request.subscribed?(ctx[:current_user], merge_request.target_project)
    end
  end
end
