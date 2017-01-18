Redmine::Plugin.register :redmine_chart do
  name 'issue graphics plugin'
  author 'NAITOH Jun'
  description 'This is a sample plugin for Redmine'
  version '0.1'
  url 'http://www.r-labs.org/projects/r-labs/wiki'
  author_url 'http://www.r-labs.org/projects/r-labs/wiki'

  project_module :redmine_chart do
    permission :view_burn_down_chart, :burn_down_charts => [:index, :get_process, :get_burn_down_data]
    permission :view_time_series_chart, :time_series_charts => [:index, :get_time_series_data]
    permission :view_gantt_chart, :gantt_charts => [:index, :get_gantt_chart_data]
    permission :view_stacked_bar_chart, :stacked_bar_charts => [:index, :get_stacked_bar_chart_data]
  end

  require "hooks"
  menu :project_menu, :redmine_chart, { :controller => 'burn_down_charts', :action => 'index'}, :param => :project_id
end
