class Loaders::FullPathLoader < Loaders::BaseLoader
  attr_reader :model

  def initialize(model)
    @model = model
  end

  def perform(keys)
    relation = model.where_full_path_in(keys)
    fulfill_all(relation, keys) { |instance| instance.full_path }
  end
end
