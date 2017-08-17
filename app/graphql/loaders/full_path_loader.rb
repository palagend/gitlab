class Loaders::FullPathLoader < Loaders::BaseLoader
  attr_reader :model, :action

  # Load an instance of a model by `full_path`. Provide an action like
  # `read_project` or `update_group` if you wish to use this loader as a
  # resolver and need to apply access controls.
  def initialize(model, action:)
    super(action: action)

    @model = model
  end

  # Allow the loader to be used as a resolver as well. Access control is
  # performed here.
  def call(_, args, ctx)
    promise = load(args['full_path'])

    filter_by_action(promise, ctx)
  end

  # `keys` is an array of full_path strings
  def perform(keys)
    found = model.where_full_path_in(keys)
    fulfill_all(keys, found.index_by(&:full_path))
  end
end
