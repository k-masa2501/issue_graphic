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
        "concat(users.lastname,' ',users.firstname) as name",
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
        "concat(users.lastname,' ',users.firstname) name",
        "count(status_id) count_total",
        "sum(case when status_id in (#{unClosed_id}) then 1 else 0 end) count")
                 .joins('left join users on users.id = issues.assigned_to_id')

    where.each do |v|
      record = record.where(v)
    end

    record = record.group(:assigned_to_id)

    return record

  end

  def self.per_period_oc(filter, days, map, format, condition)

    sql = Array.new
    keyword = ['OP','CL']
    difference = Array.new
    result = {keyword[0] => Array.new, keyword[1] => Array.new}
    keys1 = {keyword[0] => "#{keyword[0]}#{I18n.t('stacked_bar_charts.occurrence')}",
             keyword[1] => "#{keyword[1]}#{I18n.t('stacked_bar_charts.closed')}"}
    query_var1 = "ifnull(#{map[:view][:pluck]}, 'null')"
    record = Issue.joins(map[:view][:joins])

    filter.each do |v|
      query = [Issue.table_name + '.' + v[0],v[1]]
      record = record.where(query)
    end

    keys2 = record.pluck(query_var1).uniq

    days.each do |v|
      open_between = "(issues.created_on #{condition.call(v)})"
      close_between = "(issues.closed_on #{condition.call(v)})"
      sql.push("("+record.select("DATE_FORMAT(#{v},'#{format}')",
                                 "ifnull(sum#{open_between},0)",
                                 "ifnull(sum#{close_between},0)",
                                 query_var1)
                       .group(query_var1).to_sql+")")
    end

    data = ActiveRecord::Base.connection.select_rows(sql.join(" UNION ALL "))

    diff = record.where("issues.created_on > #{days[0]}")
               .where("issues.closed_on  <= #{days[0]}")
               .pluck('count(issues.id)')[0]

    (0 < data.length) and days.each do |v1|

      if 0 < (v2 = data.select {|v2| Date.parse(v1).strftime(format) == Date.parse(v2[0]).strftime(format)}).length
        v2.each do |v3|
          result[keyword[0]].push([v3[0],v3[3],v3[1]])
          result[keyword[1]].push([v3[0],v3[3],v3[2]])
          diff = diff + (v3[1] - v3[2])
        end
      else
        result[keyword[0]].push([Date.parse(v1).strftime(format),keys2[0],0])
        result[keyword[1]].push([Date.parse(v1).strftime(format),keys2[0],0])
      end
      difference.push({:date => Date.parse(v1).strftime(format), :value => diff})
    end

    return {:data => result, :keys1 => keys1, :keys2 => keys2, :diff => difference}

  end

end
