ActiveAdmin.register_page 'Single Access Control' do
  menu false

  content do

  end


  page_action :save, method: :put do
    puts 'test'
  end

  action_item :add do
    link_to "Test", admin_access_control_save_path, method: :put
  end
end