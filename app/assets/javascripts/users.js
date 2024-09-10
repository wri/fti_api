$(document).ready(function() {
  updateFields();
  $('#user_user_permission_attributes_user_role').on('change', function(){
    updateFields();
  })
})

function updateFields() {
  const userRole = $('#user_user_permission_attributes_user_role').val();
  const observerInput = $('#user_observer_id');
  const managedObserversInput = $('#user_managed_observer_ids');
  const reponsibleForCountriesInput = $('#user_responsible_for_country_ids');
  const operatorInput = $('#user_operator_id');
  const holdingInput = $('#user_holding_id');
  const qc1ObserversInput = $('#user_qc1_observer_ids');
  const qc2ObserversInput = $('#user_qc2_observer_ids');

  const showInput = (input) => {
    input.prop('disabled', false);
    input.parent().show();
  };
  const hideInput = (input) => {
    input.prop('disabled', true);
    input.parent().hide();
  };

  hideInput(operatorInput);
  hideInput(holdingInput);
  hideInput(observerInput);
  hideInput(managedObserversInput);
  hideInput(reponsibleForCountriesInput);
  hideInput(qc1ObserversInput);
  hideInput(qc2ObserversInput);

  switch (userRole) {
    case 'holding':
      showInput(holdingInput);
      break;
    case 'ngo_manager':
      showInput(qc1ObserversInput);
      showInput(qc2ObserversInput);
    case 'ngo':
      showInput(observerInput);
      showInput(managedObserversInput);
      break;
    case 'operator':
      showInput(operatorInput);
      break;
    case 'admin':
      showInput(managedObserversInput);
      showInput(reponsibleForCountriesInput);
      showInput(qc2ObserversInput);
      break;
  }
}
