import $ from 'jquery';
import Flash from './flash';
import { __ } from './locale';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

/*

 example HAML:
 ```
  %button.js-project-feature-toggle.project-feature-toggle{ type: "button",
    class: "#{'is-checked' if enabled?}",
    'aria-label': _('Toggle Cluster') }
    %input{ type: "hidden", class: 'js-project-feature-toggle-input', value: enabled? }
  ```
*/

export default class ToggleButtons {
  constructor(container, clickCallback = $.noop) {
    this.$container = $(container);
    this.clickCallback = clickCallback;
  }

  init() {
    const $toggles = this.$container.find('.js-project-feature-toggle');

    $toggles.each((index, toggle) => {
      const $toggle = $(toggle);
      const $input = $toggle.find('.js-project-feature-toggle-input');
      const isOn = convertPermissionToBoolean($input.val());

      // Get the visible toggle in sync with the hidden input
      ToggleButtons.updatetoggle($toggle, isOn);

      $(toggle).on('click', ToggleButtons.onToggleClicked.bind(this, toggle, $input));
    });
  }

  static onToggleClicked(toggle, input) {
    const $toggle = $(toggle);
    const $input = $(input);
    const previousIsOn = convertPermissionToBoolean($input.val());

    // Visually change the toggle and start loading
    ToggleButtons.updatetoggle($toggle, !previousIsOn);
    $toggle.attr('disabled', true);
    $toggle.toggleClass('is-loading');

    Promise.resolve(this.clickCallback(!previousIsOn, $toggle[0]))
      .then(() => {
        // Actually change the input value
        $input
          .val(!previousIsOn)
          .trigger('trigger-change');
      })
      .catch(() => {
        // Revert the visuals if something goes wrong
        ToggleButtons.updatetoggle($toggle, previousIsOn);
      })
      .then(() => {
        // Remove the loading indicator in any case
        $toggle.removeAttr('disabled');
        $toggle.toggleClass('is-loading');
      })
      .catch(() => {
        Flash(__('Something went wrong when toggling the button'));
      });
  }

  static updatetoggle(toggle, isOn) {
    const $toggle = $(toggle);
    $toggle.toggleClass('is-checked', isOn);
  }
}
