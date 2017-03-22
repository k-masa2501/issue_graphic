class Aggregation < ActiveRecord::Base
  unloadable

  self.primary_key = :today, :issue_id

  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus'
  belongs_to :author, :class_name => 'User'
  belongs_to :assigned_to, :class_name => 'Principal'
  belongs_to :fixed_version, :class_name => 'Version'
  belongs_to :priority, :class_name => 'IssuePriority'
  belongs_to :category, :class_name => 'IssueCategory'

  def self.get_aggs_each_daily(where) # fetch_sum_group_by_today
      data = self
               .select([:today,
                        self.arel_table[:estimated_hours].sum().as('estimated_sum'),
                        self.arel_table[:act_value].sum().as('actual_sum'),
                        self.arel_table[:plan_value].sum().as('plan_value_sum'),])
      where.each do |v|
        data = data.where(v)
      end
      data =  data.group(:today)
  end

  def self.get_aggs_each_assigned(where) # fetch_cost_each_assigned

    record = self.select(
                            "concat(users.lastname,' ',users.firstname) as name",
                            self.arel_table[:estimated_hours].sum().as('estimated_sum'),
                            self.arel_table[:act_value].sum().as('actual_sum'))
                    .joins('left join users on users.id = aggregations.assigned_to_id')

    where.each do |v|
      record = record.where(v)
    end

    record = record
                 .where("aggregations.today = (select max(today) from aggregations where project_id=#{where[0][1]})")
                 .group(:assigned_to_id)

    return record

  end

  def self.get_aggs_each_daily_assigned(where)

    record = self.select('aggregations.today as today',
                            "concat(users.lastname,' ',users.firstname) as name",
                            self.arel_table[:estimated_hours].sum().as('estimated_sum'),
                            self.arel_table[:act_value].sum().as('actual_sum'),
                            self.arel_table[:progress].sum().as('progress'))
                    .joins('left join users on users.id = aggregations.assigned_to_id')

    where.each do |v|
      record = record.where(v)
    end

    record = record.group(:today, :assigned_to_id).order('today ASC')

    return record

  end

  def self.get_both_date(where)

    max_today = self.select('max(today)')
    where.each do |v|
      max_today = max_today.where(v)
    end

    data = self.select('min(start_date) as start_date','max(due_date) as due_date')
               .where("aggregations.today = (#{max_today.to_sql})")
               .where("start_date is not NULL")
               .where("due_date is not NULL")
    where.each do |v|
      data = data.where(v)
    end

    data = data.limit(1)

    start_date = data.length > 0 ? data[0].start_date : nil
    due_date = data.length > 0 ? data[0].due_date : nil

    return start_date, due_date

  end

  def self.get_progress_each_assigned(where) # fetch_progress_each_operator

    data = self.select(
        "concat(users.lastname,' ',users.firstname) user_name",
        'aggregations.issue_id issue_id',
        'aggregations.project_id project_id',
        'issue_statuses.name status_name',
        'aggregations.progress progress')
               .joins('left join users on users.id = aggregations.assigned_to_id')
               .joins('left join issue_statuses on issue_statuses.id = aggregations.status_id')
               .where('aggregations.progress > 0')

    where.each do |v|
      data = data.where(v)
    end

    return data

  end

  #def self.get_sum_each_daily(where,  groupby, table_name=self.table_name)

  #end

  def self.get_sum(where, method)

    result = self

    where.each do |v|
      result = result.where(v)
    end

    return result.pluck("#{method}")
  end

  def self.get_sum_each_daily_data(where, map)

    return {:data => [], :keys => []} if map.blank?

    record = self.eager_load(map[:view][:joins])

    where.each do |v|
      query = [self.table_name + '.' + v[0],v[1]]
      record = record.where(query)
    end

    record = record.group(:today).group(map[:view][:pluck])

    keys = record.pluck("CASE WHEN #{map[:view][:pluck]} is NULL THEN 'null' ELSE #{map[:view][:pluck]} END").uniq
    data = record.pluck(
        "today",
        "CASE WHEN #{map[:view][:pluck]} is NULL THEN 'null' ELSE #{map[:view][:pluck]} END",
        "#{map[:method][:query]}")

    return {:data => data, :keys => keys}
  end

  def self.get_sum_each_period_data(where, map)

    return {:data => [], :keys => []} if map.blank?

    record = self.eager_load(map[:view][:joins])

    where.each do |v|
      query = [self.table_name + '.' + v[0],v[1]]
      record = record.where(query)
    end

    record = record.group(map[:format][:group]).group(map[:view][:pluck])

    keys = record.pluck("CASE WHEN #{map[:view][:pluck]} is NULL THEN 'null' ELSE #{map[:view][:pluck]} END").uniq
    data = record.pluck(
        "DATE_FORMAT(today, '#{map[:format][:pluck]}')",
        "CASE WHEN #{map[:view][:pluck]} is NULL THEN 'null' ELSE #{map[:view][:pluck]} END",
        "#{map[:method][:query]}")

    return {:data => data, :keys => keys}
  end

end
