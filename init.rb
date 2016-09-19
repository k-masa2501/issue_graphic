Redmine::Plugin.register :issue_graphic do
  name 'issue graphics plugin'
  author 'NAITOH Jun'
  description 'This is a sample plugin for Redmine'
  version '0.1'
  url 'http://www.r-labs.org/projects/r-labs/wiki'
  author_url 'http://www.r-labs.org/projects/r-labs/wiki'

  project_module :issue_graphic do
    permission :view_issue_graphics, :issue_graphics => [:index, :get_process]
  end

  module RedmineApp
    class Application < Rails::Application
      config.autoload_paths  += %W(#{config.root}/issue_graphic/lib)
    end
  end

  menu :project_menu, :issue_graphic, { :controller => 'issue_graphics', :action => 'index'}, :param => :project_id
  require_dependency 'issues_save_hook'
end
