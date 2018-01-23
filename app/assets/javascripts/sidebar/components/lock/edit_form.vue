<script>
  import editFormButtons from './edit_form_buttons.vue';
  import issuableMixin from '../../../vue_shared/mixins/issuable';
  import { __, s__, sprintf } from '../../../locale';

  export default {
    components: {
      editFormButtons,
    },
    mixins: [
      issuableMixin,
    ],
    props: {
      isLocked: {
        required: true,
        type: Boolean,
      },

      toggleForm: {
        required: true,
        type: Function,
      },

      updateLockedAttribute: {
        required: true,
        type: Function,
      },
    },
    computed: {
      lockWarning() {
        let accessLevelTranslation = s__('lock|project members');
        return sprintf(__(`Lock this %{issuableDisplayName}?
          Only
          %{accessLevel}
          will be able to comment.`), { accessLevel: `<strong>${accessLevelTranslation}</strong>`, issuableDisplayName: this.issuableDisplayName }, false);
      },
      unlockWarning() {
        let accessLevelTranslation = s__('lock|Everyone');
        return sprintf(__(`Unlock this %{issuableDisplayName}?
          %{accessLevel}
          will be able to comment.`), { accessLevel: `<strong>${accessLevelTranslation}</strong>`, issuableDisplayName: this.issuableDisplayName }, false);
      },
    },
  };
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <p
        class="text"
        v-if="isLocked"
        v-html="unlockWarning">
      </p>

      <p
        class="text"
        v-else
        v-html="lockWarning">
      </p>

      <edit-form-buttons
        :is-locked="isLocked"
        :toggle-form="toggleForm"
        :update-locked-attribute="updateLockedAttribute"
      />
    </div>
  </div>
</template>
