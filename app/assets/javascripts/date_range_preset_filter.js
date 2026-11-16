// Date range preset filter (app/inputs/date_range_preset_input.rb): dates are shown and sent only for the custom preset
$(document).on('change', '.date-range-preset', function () {
  $(this).siblings('.date-range-preset-custom').prop('hidden', this.value !== 'custom');
});

// capture phase, so the dates are emptied before ActiveAdmin skips empty inputs on submit
document.addEventListener('submit', function (event) {
  $(event.target).find('.date-range-preset').each(function () {
    if (this.value !== 'custom') {
      $(this).siblings('.date-range-preset-custom').find('input').val('');
    }
  });
}, true);
