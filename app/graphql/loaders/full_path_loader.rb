class Loaders::FullPathLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  # FIXME(nick.thomas): access control?
  def perform(keys)
    @model.where_full_path_in(keys).each do |instance|
      fulfill(instance.full_path, instance)
    end
  end
end
