Types::ProjectType = GraphQL::ObjectType.define do
  name 'Project'

  ## BasicProjectDetails entity

  field :id, !types.ID

  field :full_path, !types.ID
  field :path, types.String

  field :name_with_namespace, types.String
  field :name, types.String

  field :descripton, types.String

  field :default_branch, types.String
  field :tag_list, types.String

  field :ssh_url_to_repo, types.String
  field :http_url_to_repo, types.String
  field :web_url, types.String

  field :star_count, types.Int
  field :forks_count, types.Int

  field :created_at, Types::TimeType
  field :last_activity_at, Types::TimeType

  field :archived, types.Boolean

  # TODO(nick.thomas)
  # expose :visibility # -> field :visibility, types.VisibilityLevel
  # expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }

  field :container_registry_enabled, types.Boolean
  field :shared_runners_enabled, types.Boolean
  field :lfs_enabled, types.Boolean

=begin
  # TODO(nick.thomas): convery all these

  # Expose old field names with the new permissions methods to keep API compatible
  expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
  expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
  expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
  expose(:jobs_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
  expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

  expose :creator_id
  expose :namespace, using: 'API::Entities::Namespace'
  expose :forked_from_project, using: Entities::BasicProjectDetails, if: lambda { |project, options| project.forked? }

  # How do we do `if` in graphql?
  # expose :import_error, if: lambda { |_project, options| options[:user_can_admin_project] }
  expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) }
  expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
  expose :statistics, using: 'API::Entities::ProjectStatistics', if: :statistics

  expose :avatar_url do |user, options|
    user.avatar_url(only_path: false)
  end

  expose :shared_with_groups do |project, options|
    SharedGroup.represent(project.project_group_links.all, options)
  end

  expose :public_builds, as: :public_jobs
=end

  field :import_status, types.String
  field :ci_config_path, types.String

  field :only_allow_merge_if_pipeline_succeeds, types.Boolean
  field :request_access_enabled, types.Boolean
  field :only_allow_merge_if_all_discussions_are_resolved, types.Boolean
  field :printing_merge_request_link_enabled, types.Boolean

  field :merge_requests, types[Types::MergeRequestType] do
    argument :iid, types.ID

    resolve -> (project, args, ctx) do
      if H.can?(ctx, :read_merge_request, project)
        relation = project.merge_requests

        if args.key?('iid')
          relation.where(iid: args['iid'])
        else
          relation
        end
      else
        MergeRequest.none
      end
    end
  end
end
