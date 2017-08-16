# TODO(nick.thomas): work out how to do helpers sanely
module H
  extend self
  def can?(ctx, action, subject)
    current_user = ctx.fetch('current_user', nil)

    Ability.allowed?(current_user, action, subject)
  end

  def filter_subject(ctx, action, subject)
    subject if can?(ctx, action, subject)
  end

  def load_by_full_path(klass, path, ctx, action:)
    promise = Loaders::FullPathLoader.new(klass).load(path)
    promise.then { |project| filter_subject(ctx, action, project) } if action

    promise
  end
end

Types::QueryType = GraphQL::ObjectType.define do
  name "Query"

  # Like regular `can?`, but takes a context instead of `current_user`
  def can?(context, action, subject)
    Ability.allowed?(context['current_user'], action, subject)
  end

  field :project, Types::ProjectType do
    # The full path of the project, e.g., 'group1/group2/project'
    argument :path, !types.ID

    resolve -> (obj, args, ctx) do
      H.load_by_full_path(Project, args['path'], ctx, action: :read_project)
    end
  end
end
