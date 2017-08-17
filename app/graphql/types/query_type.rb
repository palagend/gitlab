Types::QueryType = GraphQL::ObjectType.define do
  name "Query"

  field :project, Types::ProjectType do
    argument :full_path, !types.ID

    resolve Loaders::FullPathLoader.new(Project, action: :read_project)
  end
end
