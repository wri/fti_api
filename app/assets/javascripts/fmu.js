$(document).ready(function() {
  const forestType = document.getElementById('fmu_forest_type');
  if (forestType== null || forestType.prop('disabled') == true){
    return
  }
  updateFmuFields();
  $('#fmu_country_id').on('change', function(){
    updateFmuFields();
  })
})

function updateFmuFields() {
  const countryList = {
    45: ['ufa', 'cf', 'vdc'],
    53: ['cpaet', 'cfad']
  }
  var forestTypes = $('#fmu_forest_type');
  var country = $('#fmu_country_id').val();

  if (country in countryList) {
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
  }
  $(forestTypes.select2({width: '80%'})[0].options[1]).prop('disabled', false)

  forestTypes.val([])
  forestTypes.select2({width: '80%'}).trigger('change')
}