$(document).ready(function() {
  const forestType = $('#fmu_forest_type:not([type="checkbox"])');
  if (forestType.length === 0 || forestType.prop('disabled') == true){
    return
  }
  updateFmuFields();
  $('#fmu_country_id').on('change', function(){
    updateFmuFields();
  })

  const warning = $('#forest_type_warning');
  if (warning.length > 0 && $('body').hasClass('edit')) {
    const initialValue = forestType.val();
    forestType.on('change', function() {
      warning.toggle(forestType.val() !== initialValue);
    })
  }
})

function updateFmuFields() {
  const countryList = {
    7: ['cdc', 'ccf'],
    45: ['ufa', 'cf', 'vdc'],
    53: ['cpaet', 'cfad']
  }
  var forestTypes = $('#fmu_forest_type:not([type="checkbox"])');
  var country = $('#fmu_country_id').val();
  var currentValue = forestTypes.val();

  if (country in countryList) {
    forestTypes.prop('disabled', false);
    Array.from(forestTypes.select2({width: '80%'})[0].options).forEach(op => {
      if (countryList[country].includes(op.value)) {
        $(op).prop('disabled', false);
      } else {
        $(op).prop('disabled', true);
      }
    })
  } else{
    Array.from(forestTypes.select2({width: '80%'})[0].options).forEach(op => {
      $(op).prop('disabled', true);
    })
    forestTypes.prop('disabled', true);
  }

  if (!(country in countryList) || !countryList[country].includes(currentValue)) {
    forestTypes.val([])
  }
  forestTypes.select2({width: '80%'}).trigger('change')
}
