class Loaders::FullPathLoader < Loaders::BaseLoader
  attr_reader :model

  def initialize(model)
    @model = model
  end

  def perform(keys)
    # `with_route` prevents relation.all.map(&:full_path)` from being N+1
    relation = model.where_full_path_in(keys).with_route
    fulfill_all(relation, keys) { |instance| instance.full_path }
  end
end
