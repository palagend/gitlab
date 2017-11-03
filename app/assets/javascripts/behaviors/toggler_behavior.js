// Toggle button. Show/hide content inside parent container.
// Button does not change visibility. If button has icon - it changes chevron style.
//
// %div.js-toggle-container
//   %button.js-toggle-button
//   %div.js-toggle-content
//

import Flash from '~/flash';

$(() => {
  function toggleContainer(container, toggleState) {
    const $container = $(container);

    $container
      .find('.js-toggle-button .fa')
      .toggleClass('fa-chevron-up', toggleState)
      .toggleClass('fa-chevron-down', toggleState !== undefined ? !toggleState : undefined);

    $container
      .find('.js-toggle-content')
      .toggle(toggleState);
  }

  $('body').on('click', '.js-toggle-button', function toggleButton(e) {
    e.target.classList.toggle('open');
    toggleContainer($(this).closest('.js-toggle-container'));

    const targetTag = e.currentTarget.tagName.toLowerCase();
    if (targetTag === 'a' || targetTag === 'button') {
      e.preventDefault();
    }
  });

  $('body').on('click', '.js-toggle-lazy-diff', (e) => {
    e.target.classList.remove('js-toggle-lazy-diff');
    const contentEl = $(e.target).closest('.js-toggle-container').find('.js-toggle-content');
    const tableEl = contentEl.find('tbody');
    if (tableEl.length === 0) return;

    let fileHolder = contentEl.find('.file-holder');
    const url = fileHolder.data('linesPath');

    $.ajax({
      url,
      dataType: 'JSON',
    })
    .done(({ discussion_html }) => {
      const lines = $(discussion_html).find('.line_holder');
      lines.addClass('fade-in');
      contentEl.find('tbody').prepend(lines);
      contentEl.find('.line-holder-placeholder').remove();
      fileHolder = contentEl.find('.file-holder');
      fileHolder.syntaxHighlight();
    })
    .fail(() => {
      Flash('Unable to fetch diff. Try refreshing the page');
    });
  });

  // If we're accessing a permalink, ensure it is not inside a
  // closed js-toggle-container!
  const hash = window.gl.utils.getLocationHash();
  const anchor = hash && document.getElementById(hash);
  const container = anchor && $(anchor).closest('.js-toggle-container');

  if (container) {
    toggleContainer(container, true);
    anchor.scrollIntoView();
  }
});
