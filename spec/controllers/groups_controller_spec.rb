require 'spec_helper'

describe GroupsController do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, namespace: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:owner) { group.add_owner(create(:user)).user }
  let!(:master) { group.add_master(create(:user)).user }
  let!(:developer) { group.add_developer(create(:user)).user }
  let!(:guest) { group.add_guest(create(:user)).user }

  shared_examples 'member with ability to create subgroups' do
    it 'renders the new page' do
      sign_in(member)

      get :new, parent_id: group.id

      expect(response).to render_template(:new)
    end
  end

  shared_examples 'member without ability to create subgroups' do
    it 'renders the 404 page' do
      sign_in(member)

      get :new, parent_id: group.id

      expect(response).not_to render_template(:new)
      expect(response.status).to eq(404)
    end
  end

  describe 'GET #show' do
    before do
      sign_in(user)
      project
    end

    context 'as html' do
      it 'assigns whether or not a group has children' do
        get :show, id: group.to_param

        expect(assigns(:has_children)).to be_truthy
      end
    end

    context 'as atom' do
      it 'assigns events for all the projects in the group' do
        create(:event, project: project)

        get :show, id: group.to_param, format: :atom

        expect(assigns(:events)).not_to be_empty
      end
    end
  end

  describe 'GET #new' do
    context 'when creating subgroups', :nested_groups do
      [true, false].each do |can_create_group_status|
        context "and can_create_group is #{can_create_group_status}" do
          before do
            User.where(id: [admin, owner, master, developer, guest]).update_all(can_create_group: can_create_group_status)
          end

          [:admin, :owner].each do |member_type|
            context "and logged in as #{member_type.capitalize}" do
              it_behaves_like 'member with ability to create subgroups' do
                let(:member) { send(member_type) }
              end
            end
          end

          [:guest, :developer, :master].each do |member_type|
            context "and logged in as #{member_type.capitalize}" do
              it_behaves_like 'member without ability to create subgroups' do
                let(:member) { send(member_type) }
              end
            end
          end
        end
      end
    end
  end

  describe 'POST #create' do
    context 'when creating subgroups', :nested_groups do
      [true, false].each do |can_create_group_status|
        context "and can_create_group is #{can_create_group_status}" do
          context 'and logged in as Owner' do
            it 'creates the subgroup' do
              owner.update_attribute(:can_create_group, can_create_group_status)
              sign_in(owner)

              post :create, group: { parent_id: group.id, path: 'subgroup' }

              expect(response).to be_redirect
              expect(response.body).to match(%r{http://test.host/#{group.path}/subgroup})
            end
          end

          context 'and logged in as Developer' do
            it 'renders the new template' do
              developer.update_attribute(:can_create_group, can_create_group_status)
              sign_in(developer)

              previous_group_count = Group.count

              post :create, group: { parent_id: group.id, path: 'subgroup' }

              expect(response).to render_template(:new)
              expect(Group.count).to eq(previous_group_count)
            end
          end
        end
      end
    end

    context 'when creating a top level group' do
      before do
        sign_in(developer)
      end

      context 'and can_create_group is enabled' do
        before do
          developer.update_attribute(:can_create_group, true)
        end

        it 'creates the Group' do
          original_group_count = Group.count

          post :create, group: { path: 'subgroup' }

          expect(Group.count).to eq(original_group_count + 1)
          expect(response).to be_redirect
        end
      end

      context 'and can_create_group is disabled' do
        before do
          developer.update_attribute(:can_create_group, false)
        end

        it 'does not create the Group' do
          original_group_count = Group.count

          post :create, group: { path: 'subgroup' }

          expect(Group.count).to eq(original_group_count)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET #index' do
    context 'as a user' do
      it 'redirects to Groups Dashboard' do
        sign_in(user)

        get :index

        expect(response).to redirect_to(dashboard_groups_path)
      end
    end

    context 'as a guest' do
      it 'redirects to Explore Groups' do
        get :index

        expect(response).to redirect_to(explore_groups_path)
      end
    end
  end

  describe 'GET #issues' do
    let(:issue_1) { create(:issue, project: project) }
    let(:issue_2) { create(:issue, project: project) }

    before do
      create_list(:award_emoji, 3, awardable: issue_2)
      create_list(:award_emoji, 2, awardable: issue_1)
      create_list(:award_emoji, 2, :downvote, awardable: issue_2)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular issues' do
        get :issues, id: group.to_param, sort: 'upvotes_desc'
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end

      it 'sorts least popular issues' do
        get :issues, id: group.to_param, sort: 'downvotes_desc'
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end
    end
  end

  describe 'GET #merge_requests' do
    let(:merge_request_1) { create(:merge_request, source_project: project) }
    let(:merge_request_2) { create(:merge_request, :simple, source_project: project) }

    before do
      create_list(:award_emoji, 3, awardable: merge_request_2)
      create_list(:award_emoji, 2, awardable: merge_request_1)
      create_list(:award_emoji, 2, :downvote, awardable: merge_request_2)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular merge requests' do
        get :merge_requests, id: group.to_param, sort: 'upvotes_desc'
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end

      it 'sorts least popular merge requests' do
        get :merge_requests, id: group.to_param, sort: 'downvotes_desc'
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as another user' do
      it 'returns 404' do
        sign_in(create(:user))

        delete :destroy, id: group.to_param

        expect(response.status).to eq(404)
      end
    end

    context 'as the group owner' do
      before do
        sign_in(user)
      end

      it 'schedules a group destroy' do
        Sidekiq::Testing.fake! do
          expect { delete :destroy, id: group.to_param }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end
      end

      it 'redirects to the root path' do
        delete :destroy, id: group.to_param

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PUT update' do
    before do
      sign_in(user)
    end

    it 'updates the path successfully' do
      post :update, id: group.to_param, group: { path: 'new_path' }

      expect(response).to have_gitlab_http_status(302)
      expect(controller).to set_flash[:notice]
    end

    it 'does not update the path on error' do
      allow_any_instance_of(Group).to receive(:move_dir).and_raise(Gitlab::UpdatePathError)
      post :update, id: group.to_param, group: { path: 'new_path' }

      expect(assigns(:group).errors).not_to be_empty
      expect(assigns(:group).path).not_to eq('new_path')
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting groups at the root path' do
        before do
          allow(request).to receive(:original_fullpath).and_return("/#{group_full_path}")
          get :show, id: group_full_path
        end

        context 'when requesting the canonical path with different casing' do
          let(:group_full_path) { group.to_param.upcase }

          it 'redirects to the correct casing' do
            expect(response).to redirect_to(group)
            expect(controller).not_to set_flash[:notice]
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }
          let(:group_full_path) { redirect_route.path }

          it 'redirects to the canonical path' do
            expect(response).to redirect_to(group)
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end

          context 'when the old group path is a substring of the scheme or host' do
            let(:redirect_route) { group.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              expect(response).to redirect_to(group)
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups' do
            # I.e. /groups/oups should not become /grfoo/oups
            let(:redirect_route) { group.redirect_routes.create(path: 'oups') }

            it 'does not modify the /groups part of the path' do
              expect(response).to redirect_to(group)
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end
        end
      end

      context 'when requesting groups under the /groups path' do
        context 'when requesting the canonical path' do
          context 'non-show path' do
            context 'with exactly matching casing' do
              it 'does not redirect' do
                get :issues, id: group.to_param

                expect(response).not_to have_gitlab_http_status(301)
              end
            end

            context 'with different casing' do
              it 'redirects to the correct casing' do
                get :issues, id: group.to_param.upcase

                expect(response).to redirect_to(issues_group_path(group.to_param))
                expect(controller).not_to set_flash[:notice]
              end
            end
          end

          context 'show path' do
            context 'with exactly matching casing' do
              it 'does not redirect' do
                get :show, id: group.to_param

                expect(response).not_to have_gitlab_http_status(301)
              end
            end

            context 'with different casing' do
              it 'redirects to the correct casing at the root path' do
                get :show, id: group.to_param.upcase

                expect(response).to redirect_to(group)
                expect(controller).not_to set_flash[:notice]
              end
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :issues, id: redirect_route.path

            expect(response).to redirect_to(issues_group_path(group.to_param))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end

          context 'when the old group path is a substring of the scheme or host' do
            let(:redirect_route) { group.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              get :issues, id: redirect_route.path

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups' do
            # I.e. /groups/oups should not become /grfoo/oups
            let(:redirect_route) { group.redirect_routes.create(path: 'oups') }

            it 'does not modify the /groups part of the path' do
              get :issues, id: redirect_route.path

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups plus the new path' do
            # I.e. /groups/oups/oup should not become /grfoos
            let(:redirect_route) { group.redirect_routes.create(path: 'oups/oup') }

            it 'does not modify the /groups part of the path' do
              get :issues, id: redirect_route.path

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end
        end
      end

      context 'for a POST request' do
        context 'when requesting the canonical path with different casing' do
          it 'does not 404' do
            post :update, id: group.to_param.upcase, group: { path: 'new_path' }

            expect(response).not_to have_gitlab_http_status(404)
          end

          it 'does not redirect to the correct casing' do
            post :update, id: group.to_param.upcase, group: { path: 'new_path' }

            expect(response).not_to have_gitlab_http_status(301)
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

          it 'returns not found' do
            post :update, id: redirect_route.path, group: { path: 'new_path' }

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'for a DELETE request' do
        context 'when requesting the canonical path with different casing' do
          it 'does not 404' do
            delete :destroy, id: group.to_param.upcase

            expect(response).not_to have_gitlab_http_status(404)
          end

          it 'does not redirect to the correct casing' do
            delete :destroy, id: group.to_param.upcase

            expect(response).not_to have_gitlab_http_status(301)
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

          it 'returns not found' do
            delete :destroy, id: redirect_route.path

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end

    def group_moved_message(redirect_route, group)
      "Group '#{redirect_route.path}' was moved to '#{group.full_path}'. Please update any links and bookmarks that may still have the old path."
    end
  end

  describe "PUT transfer" do
    let(:new_parent_group) { create(:group, :public) }

    before do
      sign_in(user)
    end

    context "When the current user has valid policies" do
      before do
        create(:group_member, :owner, group: new_parent_group, user: user)

        put :transfer,
          id: group.path,
          new_parent_group_id: new_parent_group.id,
          format: :js

        group.reload
      end

      it "should be success" do
        expect(response).to be_success
      end

      it "should update the parent for the group" do
        expect(group.parent).to eq(new_parent_group)
      end
    end

    context "When the current user has no valid policies" do
      let(:previous_parent) { create(:group, :public) }

      before do
        create(:group_member, :guest, group: new_parent_group, user: user)
        group.update_attribute(:parent_id, previous_parent.id)

        put :transfer,
          id: group.path,
          new_parent_group_id: new_parent_group.id,
          format: :js

        group.reload
      end

      it "should not update the parent for the group" do
        expect(group.parent).not_to be_nil
        expect(group.parent).to eq(previous_parent)
      end

      it "should be success" do
        expect(response).to be_success
      end

      it "should return an alert" do
        expect(flash[:alert]).to eq "Transfer failed: You don't have enough permissions."
      end
    end

    context "When parent_group is empty" do
      let(:previous_parent) { create(:group, :public) }

      before do
        group.update_attribute(:parent_id, previous_parent.id)

        put :transfer,
          id: group.path,
          new_parent_group_id: nil,
          format: :js

        group.reload
      end

      it "should not update the namespace for the group" do
        expect(group.parent).not_to be_nil
        expect(group.parent).to eq(previous_parent)
      end

      it "should be success" do
        expect(response).to be_success
      end

      it "should return an alert" do
        expect(flash[:alert]).to eq "Transfer failed: Please select a new parent for your group."
      end
    end
  end

  describe "PUT convert_to_root" do
    before do
      sign_in(user)
    end

    context "When the user has no valid policies" do
      let!(:group_member) { create(:group_member, :guest, group: group, user: user) }

      before do
        put :convert_to_root,
          id: group.path,
          format: :js
      end

      it "should not be success" do
        expect(response).not_to be_success
      end

      it "should render access denied" do
        expect(response).to render_template("errors/access_denied")
      end
    end

    context "When the user has valid policies" do
      before do
        put :convert_to_root,
          id: group.path,
          format: :js

        group.reload
      end

      it "should be success" do
        expect(response).to be_success
      end

      it "should update group attributes" do
        expect(group.parent).to be_nil
      end

      it "should convert group to root group" do
        expect(group.full_path).to eq(group.name)
      end
    end
  end
end
