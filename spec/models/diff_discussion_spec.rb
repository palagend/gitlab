require 'spec_helper'

describe DiffDiscussion do
  include RepoHelpers

  subject { described_class.new([diff_note]) }

  let(:project) { build_stubbed(:project, :repository) }
  let(:merge_request) { build_stubbed(:merge_request, source_project: project, target_project: project) }
  let(:diff_note) { build_stubbed(:diff_note_on_merge_request, noteable: merge_request, project: project) }

  describe '#reply_attributes' do
    it 'includes position and original_position' do
      attributes = subject.reply_attributes
      expect(attributes[:position]).to eq(diff_note.position.to_json)
      expect(attributes[:original_position]).to eq(diff_note.original_position.to_json)
    end
  end

  describe '#merge_request_version_params' do
    let(:merge_request) { build_stubbed(:merge_request, source_project: project, target_project: project, importing: true) }
    let!(:merge_request_diff1) { merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { merge_request.merge_request_diffs.create(head_commit_sha: nil) }
    let!(:merge_request_diff3) { merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'when the discussion is active' do
      it 'returns an empty hash, which will end up showing the latest version' do
        expect(subject.merge_request_version_params).to eq({})
      end
    end

    context 'when the discussion is on an older merge request version' do
      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: ".gitmodules",
          new_path: ".gitmodules",
          old_line: nil,
          new_line: 4,
          diff_refs: merge_request_diff1.diff_refs
        )
      end

      let(:diff_note) { build_stubbed(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      it 'returns the diff ID for the version to show' do
        expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff1.id)
      end
    end

    context 'when the discussion is on a comparison between merge request versions' do
      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: ".gitmodules",
          new_path: ".gitmodules",
          old_line: 4,
          new_line: 4,
          diff_refs: merge_request_diff3.compare_with(merge_request_diff1.head_commit_sha).diff_refs
        )
      end

      let(:diff_note) { build_stubbed(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      it 'returns the diff ID and start sha of the versions to compare' do
        expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff3.id, start_sha: merge_request_diff1.head_commit_sha)
      end
    end

    context 'when the discussion does not have a merge request version' do
      let(:diff_note) { build_stubbed(:diff_note_on_merge_request, noteable: merge_request, project: project, diff_refs: project.commit(sample_commit.id).diff_refs) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      it 'returns nil' do
        expect(subject.merge_request_version_params).to be_nil
      end
    end
  end
end
