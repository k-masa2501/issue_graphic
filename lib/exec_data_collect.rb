class ExecDataCollect < DaemonSpawn::Base

  def start(args)

    Rails.logger.info "start : #{Time.now}"

    next_daily = Time.parse((Date.today+1).to_s)
    next_minute = Time.now  + get_rational

    bulk_execute

    while(1)

      now = Time.now

      if now >= next_daily

        Rails.logger.debug "next_daily : #{next_daily}"
        Rails.logger.debug "now : #{now}"
        Rails.logger.debug "next_minute : #{next_minute}"

        next_daily = 1.days.since next_daily
        bulk_execute

      elsif now >= next_minute

        Rails.logger.debug "next_daily : #{next_daily}"
        Rails.logger.debug "now : #{now}"
        Rails.logger.debug "next_minute : #{next_minute}"

        gap = now - next_minute
        next_minute += get_rational
        execute(now - get_rational - gap)

      end

      sleep 1

    end

  end

  def stop
    Rails.logger.info "stop  : #{Time.now}"

    # やることがなくても、メソッドを実装しないと例外
  end

  def get_rational(x=0)
    (30+x) * 60
  end

  def get_condition
    @versions = Version.where("versions.status = 'open'").pluck('id').uniq
    @enables = EnabledModule.where(name: 'redmine_chart').pluck('project_id')
  end

  def execute(time)

    issue_aggs = []
    today = Date.today
    get_condition

    get_issues([['issues.updated_on >= ?', time]]).each do |issue|

      act_value, plan_value = get_cost(issue, today)

      aggs = Aggregation.where(issue_id: issue.id).where(today: today)[0]
      aggs = Aggregation.new if aggs.blank?
      aggs.attributes = {
          :today => today,
          :issue_id => issue.id,
          :project_id => issue.project_id,
          :tracker_id => issue.tracker_id,
          :status_id => issue.status_id,
          :priority_id => issue.priority_id,
          :assigned_to_id => issue.assigned_to_id,
          :category_id => issue.category_id,
          :fixed_version_id => issue.fixed_version_id,
          :start_date => issue.start_date,
          :due_date => issue.due_date,
          :estimated_hours => issue.estimated_hours,
          :act_value => act_value,
          :plan_value => plan_value,
          :progress => get_progress(act_value,today,issue.id)
      }
      issue_aggs << aggs
    end

    begin

      ActiveRecord::Base.transaction do

        issue_aggs.each do |v|
          v.save!
        end

      end
    rescue => e
      Rails.logger.error 'Collection of data has failed.'
      Rails.logger.error($@)
      Rails.logger.error(e)
      return false
    end

  end

  def bulk_execute

    Rails.logger.info "Start a collection of data."

    issue_aggs = []
    today = Date.today
    get_condition

    get_issues.each do |issue|

      # 予定工数から実績工数を計算
      act_value, plan_value = get_cost(issue, today)

      issue_aggs << Aggregation.new(
          :today => today,
          :issue_id => issue.id,
          :project_id => issue.project_id,
          :tracker_id => issue.tracker_id,
          :status_id => issue.status_id,
          :priority_id => issue.priority_id,
          :assigned_to_id => issue.assigned_to_id,
          :category_id => issue.category_id,
          :fixed_version_id => issue.fixed_version_id,
          :start_date => issue.start_date,
          :due_date => issue.due_date,
          :estimated_hours => issue.estimated_hours,
          :act_value => act_value,
          :plan_value => plan_value,
          :progress => get_progress(act_value,today,issue.id)
      )

    end

    # aggregationsレコードへ書き込み
    begin

      ActiveRecord::Base.transaction do

        Aggregation.delete_all(today: today) if issue_aggs.length > 0

        issue_aggs.each do |v|
          v.save!
        end

      end
    rescue => e
      Rails.logger.error 'Collection of data has failed.'
      Rails.logger.error($@)
      Rails.logger.error(e)
      return false
    end

    Rails.logger.info "Exit the collection of data."

    return true

  end

  def get_cost(issue, today)

    act_value = nil
    plan_value = nil

    if issue.estimated_hours.present? and issue.done_ratio.present?
      act_value = (issue.estimated_hours*(issue.done_ratio.quo(100))).round(1)
    end

    # 集計日における予定作業量
    if issue.due_date.present? and
        issue.start_date.present? and
        0 < (w_days = issue.due_date - (issue.start_date-1)) and
        issue.estimated_hours.present?
      if today < issue.start_date
        r_days = 0
      elsif issue.due_date < today
        r_days = w_days
      else
        r_days = today-(issue.start_date-1)
      end
      average = issue.estimated_hours.quo(w_days)
      plan_value = (average.to_f * r_days.to_i).round(1)
    end
    return act_value, plan_value
  end

  private

  def get_issues(condition=[])

    record = Issue.select(
             'issues.id as id',
             'issues.tracker_id as tracker_id',
             'issues.project_id as project_id',
             'issues.status_id as status_id',
             'issues.priority_id as priority_id',
             'issues.assigned_to_id as assigned_to_id',
             'issues.category_id as category_id',
             'issues.start_date as start_date',
             'issues.due_date as due_date',
             'issues.done_ratio as done_ratio',
             'issues.estimated_hours as estimated_hours',
             'issues.fixed_version_id as fixed_version_id')
                 .joins(:project)
                 .where(project_id: @enables)
                 .where('projects.status = 1')
                 .where(fixed_version_id: @versions)

    condition.each do |v|
      record = record.where(v) if v.present?
    end

    return record
  end

  def get_progress(act_value,today,issue_id)

    return 0 if act_value.blank?

    previous = Aggregation.where('today < ? and issue_id = ?', today, issue_id).order('today desc').limit(1).pluck('act_value')[0]

    return act_value if previous.blank?
    return (act_value - previous).round(1)

  end

end

ExecDataCollect.spawn!({
                    :working_dir => Rails.root,
                    :pid_file => File.expand_path("#{Rails.root}/tmp/rchart.pid"),
                    :log_file => File.expand_path("#{Rails.root}/log/rchart.log"),
                    :sync_log => true,
                    :singleton => true
                })