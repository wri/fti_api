$(document).ready(function() {
  const dependantFilters = {
    '.admin_monitors #q_translations_name_eq': {
      url: '/admin/monitors',
      query: 'translations_name_cont',
      order: 'name_asc',
      idField: 'name',
      textField: 'name',
      dependentOn: {
        q_country_ids: 'countries_id_eq',
        q_is_active: 'is_active_eq'
      }
    },
    '.admin_producers #q_translations_name_eq': {
      url: '/admin/producers',
      query: 'translations_name_cont',
      order: 'operator_translations.name_asc',
      idField: 'name',
      textField: 'name',
      dependentOn: {
        q_country_id: 'country_id_eq'
      }
    },
    '#q_written_infraction': {
      url: '/admin/laws',
      query: 'written_infraction_cont',
      order: 'written_infraction_asc',
      idField: 'written_infraction',
      textField: 'written_infraction',
      dependentOn: {
        q_country_id: 'country_id_eq',
        q_subcategory_id: 'subcategory_id_eq'
      }
    },
    '#q_infraction': {
      url: '/admin/laws',
      query: 'infraction_cont',
      order: 'infraction_asc',
      idField: 'infraction',
      textField: 'infraction',
      dependentOn: {
        q_country_id: 'country_id_eq',
        q_subcategory_id: 'subcategory_id_eq'
      }
    },
    '#q_sanctions': {
      url: '/admin/laws',
      query: 'sanctions_cont',
      order: 'sanctions_asc',
      idField: 'sanctions',
      textField: 'sanctions',
      dependentOn: {
        q_country_id: 'country_id_eq',
        q_subcategory_id: 'subcategory_id_eq'
      }
    },
  }

  setTimeout(() => {
    Object.keys(dependantFilters).forEach((filterId) => {
      $(filterId).select2({
        minimumInputLength: 0,
        placeholder: '',
        allowClear: true,
        ajax: {
          url: dependantFilters[filterId].url,
          dataType: 'json',
          delay: 250,
          cache: true,
          data: function (params) {
            const query = {};
            query[dependantFilters[filterId].query] = params.term;
            Object.keys(dependantFilters[filterId].dependentOn).forEach((dependentFilterId) => {
              const dependentFilterValue = $(`#${dependentFilterId}`).val();
              if (dependentFilterValue) query[dependantFilters[filterId].dependentOn[dependentFilterId]] = dependentFilterValue;
            });

            return {
              order: dependantFilters[filterId].order,
              q: query
            };
          },
          processResults: function (data) {
            return {
              results: data.map((item) => ({
                id: item[dependantFilters[filterId].idField],
                text: item[dependantFilters[filterId].textField]
              }))
            };
          }
        }
      });
    });
  }, 500);
});
