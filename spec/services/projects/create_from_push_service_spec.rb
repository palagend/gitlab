require 'spec_helper'

describe Projects::CreateFromPushService do
  let(:user) { create(:user) }
  let(:project_id) { "nonexist" }
  let(:namespace) { user&.namespace }
  let(:protocol) { 'http' }

  subject { described_class.new(user, project_id, namespace, cmd, protocol) }

  context 'when command is git receive pack' do
    let(:cmd) { 'git-receive-pack' }

    it 'creates project' do
      expect_any_instance_of(Projects::CreateService).to receive(:execute).and_call_original

      expect { subject.execute }.to change { Project.count }.by(1)
    end

    it 'raises project creation error when project creation fails' do
      allow_any_instance_of(Project).to receive(:saved?).and_return(false)

      expect { subject.execute }.to raise_error(Gitlab::GitAccess::ProjectCreationError)
    end

    context 'when user is nil' do
      let(:user) { nil }

      subject { described_class.new(user, project_id, namespace, cmd, protocol) }

      it 'returns nil' do
        expect_any_instance_of(Projects::CreateService).not_to receive(:execute)

        expect(subject.execute).to be_nil
      end
    end
  end

  context 'when command is not git receive pack' do
    let(:cmd) { 'git-upload-pack' }

    subject { described_class.new(user, project_id, namespace, cmd, protocol) }

    it 'returns nil' do
      expect_any_instance_of(Projects::CreateService).not_to receive(:execute)

      expect(subject.execute).to be_nil
    end
  end
end
