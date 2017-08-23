Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :project, Types::ProjectType do
    argument :full_path, !types.ID do
      description 'The full path of the project, e.g., "gitlab-org/gitlab-ce"'
    end

    authorize :read_project

    resolve Loaders::FullPathLoader[:project]
  end

  field :merge_request, Types::MergeRequestType do
    argument :project, !types.ID do
      description 'The full path of the target project, e.g., "gitlab-org/gitlab-ce"'
    end

    argument :iid, !types.ID do
      description 'The IID of the merge request, e.g., "1"'
    end

    authorize :read_merge_request

    resolve Loaders::IidLoader[:merge_request]
  end
end
