# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  resources :projects do
    resources :issue_graphics do
      get  'get_process', :on => :collection
    end
  end
end
