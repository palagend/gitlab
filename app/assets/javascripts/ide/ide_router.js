import Vue from 'vue';
import VueRouter from 'vue-router';
import store from './stores';
import flash from '../flash';
import {
  getTreeEntry,
} from './stores/utils';

Vue.use(VueRouter);

/**
 * Routes below /-/ide/:

/project/h5bp/html5-boilerplate/blob/master
/project/h5bp/html5-boilerplate/blob/master/app/js/test.js

/project/h5bp/html5-boilerplate/mr/123
/project/h5bp/html5-boilerplate/mr/123/app/js/test.js

/workspace/123
/workspace/project/h5bp/html5-boilerplate/blob/my-special-branch
/workspace/project/h5bp/html5-boilerplate/mr/123

/ = /workspace

/settings
*/

// Unfortunately Vue Router doesn't work without at least a fake component
// If you do only data handling
const EmptyRouterComponent = {
  render(createElement) {
    return createElement('div');
  },
};

const router = new VueRouter({
  mode: 'history',
  base: `${gon.relative_url_root}/-/ide/`,
  routes: [
    {
      path: '/project/:namespace/:project',
      component: EmptyRouterComponent,
      children: [
        {
          path: ':targetmode/:branch/*',
          component: EmptyRouterComponent,
        },
        {
          path: 'merge_requests/:mrid',
          component: EmptyRouterComponent,
        },
      ],
    },
  ],
});

router.beforeEach((to, from, next) => {
  if (to.params.namespace && to.params.project) {
    store.dispatch('getProjectData', {
      namespace: to.params.namespace,
      projectId: to.params.project,
    })
    .then(() => {
      const fullProjectId = `${to.params.namespace}/${to.params.project}`;

      if (to.params.branch) {
        store.dispatch('getBranchData', {
          projectId: fullProjectId,
          branchId: to.params.branch,
        });

        store.dispatch('getTreeData', {
          projectId: fullProjectId,
          branch: to.params.branch,
          endpoint: `/tree/${to.params.branch}`,
        })
        .then(() => {
          if (to.params[0]) {
            const treeEntry = getTreeEntry(store, `${to.params.namespace}/${to.params.project}/${to.params.branch}`, to.params[0]);
            if (treeEntry) {
              store.dispatch('handleTreeEntryAction', treeEntry);
            }
          }
        })
        .catch((e) => {
          flash('Error while loading the branch files. Please try again.', 'alert', document, null, false, true);
          throw e;
        });
      } else if (to.params.mrid) {
        store.dispatch('getMergeRequestData', {
          projectId: fullProjectId,
          mergeRequestId: to.params.mrid,
        })
        .then((mr) => {
          store.dispatch('getBranchData', {
            projectId: fullProjectId,
            branchId: mr.source_branch,
          });

          store.dispatch('getTreeData', {
            projectId: fullProjectId,
            branch: mr.source_branch,
            endpoint: `/tree/${mr.source_branch}`,
          })
          .then(() => {
            const treeEntry = getTreeEntry(store, `${to.params.namespace}/${to.params.project}/${mr.source_branch}`, '/');
            if (treeEntry) {
              store.dispatch('handleTreeEntryAction', treeEntry);
            }

            store.dispatch('getMergeRequestChanges', {
              projectId: fullProjectId,
              mergeRequestId: to.params.mrid,
            })
            .then((mrChanges) => {
              mrChanges.changes.forEach((change) => {
                console.log('CHANGE : ', change);

                const changeTreeEntry = getTreeEntry(store, `${to.params.namespace}/${to.params.project}/${mr.source_branch}`, change.new_path);

                console.log('Tree ENtry for the change ' , changeTreeEntry, change.diff);

                if (changeTreeEntry) {
                  store.dispatch('setFileMrDiff', { file: changeTreeEntry, mrDiff: change.diff });
                  store.dispatch('setFileTargetBranch', { file: changeTreeEntry, targetBranch: mrChanges.target_branch });
                  store.dispatch('getFileData', changeTreeEntry);
                }
              });
            })
            .catch((e) => {
              flash('Error while loading the merge request changes. Please try again.');
              throw e;
            });

            store.dispatch('getMergeRequestNotes', {
              projectId: fullProjectId,
              mergeRequestId: to.params.mrid,
            })
            .then((mrNotes) => {
              console.log('NOTES : ', mrNotes);
            })
            .catch((e) => {
              flash('Error while loading the merge request notes. Please try again.');
              throw e;
            });

          })
          .catch((e) => {
            flash('Error while loading the branch files. Please try again.');
            throw e;
          });
        })
        .catch((e) => {
          throw e;
        });
      }
    })
    .catch((e) => {
      flash('Error while loading the project data. Please try again.', 'alert', document, null, false, true);
      throw e;
    });
  }

  next();
});

export default router;
