
var dependentFilterInitializer = function() {
  configureSelect2(document);

  $(document).on('has_many_add:after', function(event, container) {
    configureSelect2(container);
  });

  function configureSelect2(container) {
    $('select.dependent-select', container).each(function(i, el) {
      setupSelect2(el);
    });

    function setupSelect2(el) {
      const select = $(el);
      const dependentOn = select.data('dependent-on');
      const url = select.data('url');
      const query = select.data('q');
      const idField = select.data('id-field');
      const textField = select.data('text-field');
      const order = select.data('order');

      select.select2({
        minimumInputLength: 0,
        placeholder: '',
        allowClear: true,
        ajax: {
          url,
          dataType: 'json',
          delay: 250,
          cache: true,
          data: function (params) {
            const q = {};
            q[query] = params.term;
            Object.keys(dependentOn).forEach((dependentFilterId) => {
              const key = `q_${dependentFilterId}`;
              const ransackQuery = dependentOn[dependentFilterId];
              const dependentFilterValue = $(`#${key}`).val();
              if (dependentFilterValue) q[ransackQuery] = dependentFilterValue;
            });

            return {
              order,
              q
            };
          },
          processResults: function (data) {
            return {
              results: data.map((item) => ({
                id: item[idField],
                text: item[textField]
              }))
            };
          }
        }
      });
    }
  }
};
$(dependentFilterInitializer);
$(document).on('turbolinks:load turbo:load', dependentFilterInitializer);
