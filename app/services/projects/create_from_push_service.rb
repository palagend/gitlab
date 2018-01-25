module Projects
  class CreateFromPushService < BaseService
    attr_reader :user, :project_id, :namespace, :cmd, :protocol

    def initialize(user, project_id, namespace, cmd, protocol)
      @user = user
      @project_id = project_id
      @namespace = namespace
      @cmd = cmd
      @protocol = protocol
    end

    def execute
      return unless user && receive_pack?

      project = Projects::CreateService.new(user, project_params).execute

      if project.saved?
        Gitlab::Checks::ProjectCreated.new(user, project, protocol).add_project_created_message
      else
        raise Gitlab::GitAccess::ProjectCreationError, "Could not create project: #{project.errors.full_messages.join(', ')}"
      end

      project
    end

    private

    def project_params
      {
        description: "",
        path: project_id.gsub(/\.git$/, ''),
        namespace_id: namespace&.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s
      }
    end

    def receive_pack?
      cmd == 'git-receive-pack'
    end
  end
end
