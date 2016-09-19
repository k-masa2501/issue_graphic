class ExecDataCollect

  def self.execute(arg={})

    Rails.logger.debug "Start a collection of data."

    # 集計日がチケットの開始～終了期間に含まれるレコードを収集
    issue_aggs = []
    issue_custom_agg = []
    today = Date.strptime('2016-8-7','%Y-%m-%d')#Date.today.to_s
    issue_rc = get_issues(arg[:issue_id], arg[:project_id])

    issue_rc.each do |issue|

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
          :start_date => issue.start_date,
          :due_date => issue.due_date,
          :estimated => issue.estimated_hours,
          :act_value => act_value,
          :plan_value => plan_value,
          :progress => get_progress(act_value,today,issue.id),
          :custom_value => issue.custom_valule,
          :subject => issue.subject
      )

    end

    # aggregationsレコードへ書き込み
    begin

      ActiveRecord::Base.transaction do

        if arg[:issue_id].present?
          Aggregation.where('today =? and issue_id =?',today, arg[:issue_id]).delete_all
        else
          Aggregation.delete_all(today: today)
        end

        Aggregation.import issue_aggs
      end
    rescue => e
      Rails.logger.error 'Collection of data has failed.'
      Rails.logger.error($@)
      Rails.logger.error(e)
      return
    end

    Rails.logger.debug "Exit the collection of data."

  end

  def self.get_cost(issue, today)

    act_value = nil
    plan_value = nil

    if issue.estimated_hours.present? and issue.done_ratio.present?
      act_value = (issue.estimated_hours*(issue.done_ratio.quo(100))).round(2)
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
      plan_value = (average.to_f * r_days.to_i).round(2)
    end
    return act_value, plan_value
  end

  private

  def self.get_issues(issue_id=nil, project_id=nil)

    cf_t = CustomField.arel_table

    record = Issue.select(
             'issues.id as id',
             'issues.project_id as project_id',
             'issues.tracker_id as tracker_id',
             'issues.status_id as status_id',
             'issues.priority_id as priority_id',
             'issues.assigned_to_id as assigned_to_id',
             'issues.category_id as category_id',
             'issues.start_date as start_date',
             'issues.due_date as due_date',
             'issues.done_ratio as done_ratio',
             'issues.estimated_hours as estimated_hours',
             'issues.subject as subject',
             "group_concat(custom_fields.id , '=' ,custom_values.value SEPARATOR ',') as custom_valule")
        .joins('LEFT JOIN custom_values on issues.id = custom_values.customized_id')
        .joins('LEFT JOIN custom_fields on custom_values.custom_field_id = custom_fields.id')
        .where(cf_t[:field_format].eq('enumeration').or(cf_t[:field_format].eq(nil)))
        .where(cf_t[:type].eq('IssueCustomField').or(cf_t[:type].eq(nil)))
    record = record.where(id: issue_id) if issue_id.present?
    record = record.where(project_id: project_id) if project_id.present?
    record = record.group(:id)

    return record
  end

  def self.get_progress(act_value,today,issue_id)

    return 0 if act_value.blank?

    previous = Aggregation.where('today = ? and issue_id = ?', today-1, issue_id).limit(1).pluck('act_value')[0]

    return act_value if previous.blank?
    return (act_value - previous).round(2)

  end

end