class Loaders::IidLoader < Loaders::BaseLoader
  class << self
    def merge_request
      proc do |obj, args, ctx|
        Loaders::FullPathLoader.for(Project).load(args[:project]).then do |project|
          iid = args[:iid]
          self.for(project, :merge_requests).load(iid)
        end
      end
    end
  end

  attr_reader :project, :relation_name

  def initialize(project, relation_name)
    @project = project
    @relation_name = relation_name
  end

  def perform(keys)
    relation = project.public_send(relation_name).where(iid: keys)
    fulfill_all(relation, keys) { |instance| instance.iid.to_s }
  end
end
