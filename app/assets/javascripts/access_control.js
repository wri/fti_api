$(document).ready(function() {
  $('#access-control input[type="checkbox"]').on('change', onChangePermissions)
})

function onChangePermissions(e){
  var permissions = JSON.parse($('#user_permission_permissions').val());

  var isChecked = e.currentTarget.checked;
  var id = e.currentTarget.id;

  permissions[id] = (isChecked) ? { manage: {} } : { read: {} };

  $('#user_permission_permissions').val(JSON.stringify(permissions));
}
