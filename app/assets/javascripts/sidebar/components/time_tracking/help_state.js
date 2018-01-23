export default {
  name: 'time-tracking-help-state',
  props: {
    rootPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    href() {
      return `${this.rootPath}help/workflow/time_tracking.md`;
    },
  },
  template: `
    <div class="time-tracking-help-state">
      <div class="time-tracking-info">
        <h4>
          {{ __('Track time with quick actions') }}
        </h4>
        <p>
          {{ __('Quick actions can be used in the issues description and comment boxes.') }}
        </p>
        <p>
          <code>
            {{ __('/estimate') }}
          </code>
          {{ __('will update the estimated time with the latest command.') }}
        </p>
        <p>
          <code>
            {{ __('/spend') }}
          </code>
          {{ __('will update the sum of the time spent.') }}
        </p>
        <a
          class="btn btn-default learn-more-button"
          :href="href"
        >
          {{ __('Learn more') }}
        </a>
      </div>
    </div>
  `,
};
