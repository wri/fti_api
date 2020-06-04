$(document).ready(function() {
  updateFmuFields();
  $('#fmu_country_id').on('change', function(){
    updateFmuFields();
  })
})

function updateFmuFields() {
  const countryList = {
    7: [0],
    45: [0, 1, 2, 3],
    47: [0],
    53: [0, 4, 5]
  }
  var forestTypes = $('#fmu_forest_type');
  var country = $('#fmu_country_id').val();

  if (country in countryList) {
    forestTypes.prop('disabled', false);
    forestTypes.parent().show();

    Array.from(forestTypes.select2({width: '80%'})[0].options).forEach( op => {
      if (countryList[country].includes(parseInt(op.value))) {
        $(op).prop('disabled', false);
      } else {
        $(op).prop('disabled', true);
      }
    })
    forestTypes.val([])
    forestTypes.select2({width: '80%'}).trigger('change')
  }
  else {
    forestTypes.prop('disabled', true);
    forestTypes.parent().hide();
  }
}