class Loaders::IidLoader < Loaders::BaseLoader
  class << self
    def merge_request(obj, args, ctx)
      iid = args[:iid]
      promise = Loaders::FullPathLoader.project_by_full_path(args[:project])

      promise.then do |project|
        merge_request_by_project_and_iid(project, iid)
      end
    end

    def merge_request_by_project_and_iid(project, iid)
      self.for(project, :merge_requests).load(iid)
    end
  end

  attr_reader :project, :relation_name

  def initialize(project, relation_name)
    @project = project
    @relation_name = relation_name
  end

  def perform(keys)
    relation = project.public_send(relation_name).where(iid: keys) # rubocop:disable GitlabSecurity/PublicSend
    fulfill_all(relation, keys) { |instance| instance.iid.to_s }
  end
end
