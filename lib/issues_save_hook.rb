class IssuesSaveHook < Redmine::Hook::Listener

  def controller_issues_new_after_save(context)
    save_issues(context)
  end

  def controller_issues_edit_after_save(context)
    save_issues(context)
  end

  private

  def save_issues(context)

    issue_to = context[:issue]

    data = Aggregation.where('today = ? and project_id = ?', Date.today.to_s, issue_to.project_id).limit(1)
    file = Rails.root.to_s << '/tmp/lock_' << issue_to.project_id.to_s
    if data.length <= 0
      Thread.start do
        lock = File.open(file, 'w') do |lock_file|
          if lock_file.flock(File::LOCK_EX|File::LOCK_NB)
            return  if Aggregation.where('today = ? and project_id = ?', Date.today.to_s, issue_to.project_id).limit(1).length > 0
            ExecDataCollect.execute({:issue_id => nil, :project_id => issue_to.project_id})
          else
            Rails.logger.error '他のプロセスが実行中です'
            puts
          end
        end
        lock.close
      end
    else
      Thread.start do
        ExecDataCollect.execute({:issue_id => issue_to.id, :project_id => issue_to.project_id})
      end
    end
  end

end