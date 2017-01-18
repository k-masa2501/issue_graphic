# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do

  resources :projects do

    resources :burn_down_charts do
      get  'get_process', :on => :collection
      get  'get_burn_down_data', :on => :collection
    end

    resources :time_series_charts do
      get  'get_time_series_data', :on => :collection
    end

    resources :gantt_charts do
      get  'get_gantt_chart_data', :on => :collection
    end

    resources :stacked_bar_charts do
      get  'get_stacked_bar_chart_data', :on => :collection
    end

  end

end
