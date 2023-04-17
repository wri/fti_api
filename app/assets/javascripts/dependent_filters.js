const dependentFiltersInitializer = function() {
  function getCommonElements(...arrays) {
    if (arrays.length === 0) return [];
    if (arrays.length <= 1) return arrays[0];

    const referenceArray = arrays.shift();
    return referenceArray.filter((element) => {
      return arrays.every((array) => {
        return array.includes(element);
      });
    });
  }

  $('.dependent-filters').each((i, el) => {
    setupDependentFilters(el);
  });

  function setupDependentFilters(el) {
    const filters = $(el).data('filters');

    if (!filters) {
      throw new Error('No filters found in data-filters attribute');
    }

    // Create a map of dependent filters
    // e.g. { "city_id": ["state_id"], "area_id": ["city_id", "state_id"] }
    // this is reverse of the filters object
    const dependentFilters = {};
    Object.keys(filters).forEach(key => {
      Object.keys(filters[key]).forEach(key2 => {
        if (dependentFilters[key2] == undefined) {
          dependentFilters[key2] = [];
        }
        if (!dependentFilters[key2].includes(key)) {
          dependentFilters[key2].push(key);
        }
      });
    });

    Object.keys(filters).forEach(parentFilterKey => {
      const $parentFilter = $(`#q_${parentFilterKey}`);
      if ($parentFilter.length === 0) {
        throw new Error(`No filter found with id #q_${parentFilterKey}`);
      }
      $parentFilter.on('change', onFilterChange.bind(null, parentFilterKey));
      // trigger change after load for initial values
      setTimeout(() => {
        $parentFilter.trigger('change');
      }, 200);
    });

    function onFilterChange(parentKey, e) {
      const id = e.target.value;

      Object.keys(filters[parentKey]).forEach(key => {
        const parentIds = dependentFilters[key];
        let anyParentSelectedValue = false;
        const allowedIdsFromAllFilters = parentIds.map(parentId => {
          const selectedValue = $(`#q_${parentId}`).val();
          const isValueSelected = ![null, undefined, '', 'null'].includes(selectedValue);
          anyParentSelectedValue = anyParentSelectedValue || isValueSelected;
          return filters[parentId][key][selectedValue] && filters[parentId][key][selectedValue].map(x => x.toString());
        }).filter(x => x);
        const allowedIds = getCommonElements(...allowedIdsFromAllFilters);

        const $select = $(`#q_${key}`);
        if ($select.length === 0) {
          throw new Error(`No filter found with id #q_${key}`);
        }
        const selectedValues = [$select.val()].flat();

        Array.from($select[0].options).forEach(option => {
          if (!anyParentSelectedValue || (allowedIds && allowedIds.includes(option.value.toString()))) {
            $(option).prop('disabled', false);
          } else {
            $(option).prop('disabled', true);
          }
        });

        if (allowedIds && anyParentSelectedValue) {
          const selectedValuesAllowed = getCommonElements(selectedValues, allowedIds);
          if (selectedValuesAllowed.length === 0) {
            $select.val(null);
          } else if (selectedValuesAllowed.length < selectedValues.length) {
            $select.val(selectedValuesAllowed);
          }
        }

        $select.trigger('change');
      });
    }
  }
};
$(dependentFiltersInitializer);
$(document).on('turbolinks:load turbo:load', dependentFiltersInitializer);
