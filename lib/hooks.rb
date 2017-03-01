class Hooks < Redmine::Hook::ViewListener
  # This just renders the partial in
  # app/views/hooks/my_plugin/_view_issues_form_details_bottom.rhtml
  # The contents of the context hash is made available as local variables to the partial.
  #
  # Additional context fields
  #   :issue  => the issue this is edited
  #   :f      => the form object to create additional fields

  def view_issues_form_details_bottom(context={})
    context[:controller].send(:render_to_string, {
        :partial => "view_hooks/view_issues_form_details_bottom",
        :locals => {issue: context[:issue]}
    })
  end

  def view_issues_sidebar_issues_bottom(context={})
    context[:controller].send(:render_to_string, {
        :partial => "view_hooks/view_issues_sidebar_issues_bottom",
        :locals => {project_identifier: context[:project].identifier}
    })
  end

end
