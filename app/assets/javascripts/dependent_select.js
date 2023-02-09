
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
      const url = select.data('url');
      const queryObject = select.data('q') || {};
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
            // example of queryObject
            // query: {
            //  translations_name_cont: 'search_term',
            //  countries_id_eq: 'q_country_ids_value',
            //  is_active_eq: 'q_is_active_value'
            // }
            // ransack search matcher is the key and the value is either:
            // 1.  'search_term'
            // 2. arbitrary value
            // 3. current value of input field when id is provided with pattern {ID}_value
            Object.keys(queryObject).forEach((ransackQuery) => {
              const queryElement = queryObject[ransackQuery];
              if (queryElement === 'search_term') {
                q[ransackQuery] = params.term;
              } else if (queryElement.endsWith('_value')) {
                const elementValue = $(`#${queryElement.replace('_value', '')}`).val();
                if (elementValue) q[ransackQuery] = elementValue;
              } else {
                q[ransackQuery] = queryElement;
              }
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
