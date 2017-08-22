# Helper methods for all loaders
class Loaders::BaseLoader < GraphQL::Batch::Loader
  def fulfill_all(results, keys, &blk)
    results.each do |result|
      key = yield result
      fulfill(key, result)
    end

    keys.each { |key| fulfill(key, nil) unless fulfilled?(key) }
  end
end
