class RedmineChartIssue < Issue
  unloadable

  def self.get_task_progress_rate(where)

    data = self.select("id",
                       "subject",
                       "start_date",
                       "due_date",
                       "done_ratio done_rate",
                       "status_id",
                       "users.firstname name",
                       "estimated_hours estimated",
                       "estimated_hours*(done_ratio*0.01) act_rate")
               .joins("left join users on users.id = issues.assigned_to_id")

    where.each do |v|
      data = data.where(v)
    end

    data = data.order('start_date ASC')
  end

  def self.get_progress_total_rate(where)

    data = self.select("min(start_date) start_date",
                       "max(due_date) due_date",
                       "avg(done_ratio) done_rate",
                       "sum(estimated_hours) estimated",
                       "sum(estimated_hours)*(avg(done_ratio)*0.01) act_rate",
                       "(sum(estimated_hours) - (sum(estimated_hours)*(avg(done_ratio)*0.01))) rem_rate",
                       "99999 as status_id")

    where.each do |v|
      data = data.where(v)
    end

    data = data.group(:project_id)

    return data

  end

  def self.get_total_each_assigned(where)

    record = Issue.select(
        "concat(users.firstname,' ',users.lastname) as name",
        "sum(estimated_hours) as estimated_total",
        "(sum(estimated_hours) - (sum(estimated_hours)*(avg(done_ratio)*0.01))) remaining_total")
                 .joins('left join users on users.id = issues.assigned_to_id')

    where.each do |v|
      record = record.where(v)
    end

    record = record.group(:assigned_to_id)

    return record

  end

  def self.get_total_each_fixedVersion(where)

    record = Issue.select(
        "sum(estimated_hours) estimated_total",
        "(sum(estimated_hours) - (sum(estimated_hours)*(avg(done_ratio)*0.01))) remaining_total"
    )

    where.each do |v|
      record = record.where(v)
    end

    record = record.group(:project_id)

    return record

  end

  def self.get_count_each_assigned(where)

    unClosed_id = IssueStatus.where(is_closed: 0).pluck("id").join(",")

    record = Issue.select(
        "concat(users.firstname,' ',users.lastname) name",
        "count(status_id) count_total",
        "sum(case when status_id in (#{unClosed_id}) then 1 else 0 end) count")
                 .joins('left join users on users.id = issues.assigned_to_id')

    where.each do |v|
      record = record.where(v)
    end

    record = record.group(:assigned_to_id)

    return record

  end

end
