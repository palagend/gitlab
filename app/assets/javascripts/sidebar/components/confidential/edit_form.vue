<script>
  import editFormButtons from './edit_form_buttons.vue';
  import { s__, sprintf } from '../../../locale';

  export default {
    components: {
      editFormButtons,
    },
    props: {
      isConfidential: {
        required: true,
        type: Boolean,
      },
      toggleForm: {
        required: true,
        type: Function,
      },
      updateConfidentialAttribute: {
        required: true,
        type: Function,
      },
    },
    computed: {
      confidentialityOnWarning() {
        let accessLevelTranslation = s__('confidentiality|at least Reporter access');
        return sprintf(s__(`confidentiality|You are going to turn on the confidentiality. This means that only team members with
          %{accessLevel}
          are able to see and leave comments on the issue.`),
        { accessLevel: `<strong>${accessLevelTranslation}</strong>` }, false);
      },
      confidentialityOffWarning() {
        let accessLevelTranslation = s__('confidentiality|everyone');
        return sprintf(s__(`confidentiality|You are going to turn off the confidentiality. This means
          %{accessLevel}
          will be able to see and leave a comment on this issue.`),
          { accessLevel: `<strong>${accessLevelTranslation}</strong>` }, false);
      },
    },
  };
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p
          v-if="!isConfidential"
          v-html="confidentialityOnWarning">
        </p>
        <p
          v-else
          v-html="confidentialityOffWarning">
        </p>
        <edit-form-buttons
          :is-confidential="isConfidential"
          :toggle-form="toggleForm"
          :update-confidential-attribute="updateConfidentialAttribute"
        />
      </div>
    </div>
  </div>
</template>
