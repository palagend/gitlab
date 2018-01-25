import Vue from 'vue';
import store from '~/ide/stores';
import repoTab from '~/ide/components/repo_tab.vue';
import { file, resetStore } from '../helpers';

describe('RepoTab', () => {
  let vm;

  function createComponent(propsData) {
    const RepoTab = Vue.extend(repoTab);

    return new RepoTab({
      store,
      propsData,
    }).$mount();
  }

  afterEach(() => {
    resetStore(vm.$store);
  });

  it('renders a close link and a name link', () => {
    vm = createComponent({
      tab: file(),
    });
    vm.$store.state.openFiles.push(vm.tab);
    const close = vm.$el.querySelector('.multi-file-tab-close');
    const name = vm.$el.querySelector(`[title="${vm.tab.url}"]`);

    expect(close.innerHTML).toContain('#close');
    expect(name.textContent.trim()).toEqual(vm.tab.name);
  });

  it('fires clickFile when the link is clicked', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'clickFile');

    vm.$el.click();

    expect(vm.clickFile).toHaveBeenCalledWith(vm.tab);
  });

  it('calls closeFile when clicking close button', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'closeFile');

    vm.$el.querySelector('.multi-file-tab-close').click();

    expect(vm.closeFile).toHaveBeenCalledWith(vm.tab);
  });

  it('shows changed icon if tab is changed', () => {
    const tab = file('changedFile');
    tab.changed = true;
    vm = createComponent({
      tab,
    });

    expect(vm.changedIcon).toBe('file-modified');
  });

  it('changes icon on hover', (done) => {
    const tab = file();
    tab.changed = true;
    vm = createComponent({
      tab,
    });

    vm.$el.dispatchEvent(new Event('mouseover'));

    Vue.nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.multi-file-modified')).toBeNull();

        vm.$el.dispatchEvent(new Event('mouseout'));
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(vm.$el.querySelector('.multi-file-modified')).not.toBeNull();

        done();
      })
      .catch(done.fail);
  });

  describe('methods', () => {
    describe('closeTab', () => {
      it('closes tab if file has changed', (done) => {
        const tab = file();
        tab.changed = true;
        tab.opened = true;
        vm = createComponent({
          tab,
        });
        vm.$store.state.openFiles.push(tab);
        vm.$store.state.changedFiles.push(tab);
        vm.$store.dispatch('setFileActive', tab);

        vm.$el.querySelector('.multi-file-tab-close').click();

        vm.$nextTick(() => {
          expect(tab.opened).toBeFalsy();
          expect(vm.$store.state.changedFiles.length).toBe(1);

          done();
        });
      });

      it('closes tab when clicking close btn', (done) => {
        const tab = file('lose');
        tab.opened = true;
        vm = createComponent({
          tab,
        });
        vm.$store.state.openFiles.push(tab);
        vm.$store.dispatch('setFileActive', tab);

        vm.$el.querySelector('.multi-file-tab-close').click();

        vm.$nextTick(() => {
          expect(tab.opened).toBeFalsy();

          done();
        });
      });
    });
  });
});
