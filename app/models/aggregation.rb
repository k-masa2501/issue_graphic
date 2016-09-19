class Aggregation < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus'
  belongs_to :author, :class_name => 'User'
  belongs_to :assigned_to, :class_name => 'Principal'
  belongs_to :fixed_version, :class_name => 'Version'
  belongs_to :priority, :class_name => 'IssuePriority'
  belongs_to :category, :class_name => 'IssueCategory'
  has_many :aggs_custom_today, :class_name => 'AggsCustomField', :foreign_key => 'today'
  has_many :aggs_custom_issue, :class_name => 'AggsCustomField', :foreign_key => 'issue_id'

  #acts_as_attachable :delete_permission => :manage_foos

  #validates_presence_of :subject
  #validates_length_of :subject, :maximum => 255

  def self.get_sum_group_by_today(where)
      data = self
               .select([:today,
                        self.arel_table[:estimated].sum().as('estimated_sum'),
                        self.arel_table[:act_value].sum().as('actual_sum'),
                        self.arel_table[:plan_value].sum().as('plan_value_sum'),])
      where.each do |v|
        data = data.where(v)
      end
      data =  data.group(:today)
  end

  def self.get_assign_act_cost(where)

    assign_to = self.select('aggregations.today as today',
                            "concat(users.firstname,' ',users.lastname) as name",
                            self.arel_table[:estimated].sum().as('estimated_sum'),
                            self.arel_table[:act_value].sum().as('actual_sum'),
                            self.arel_table[:progress].sum().as('progress'))
                    .joins('left join users on users.id = aggregations.assigned_to_id')

    where.each do |v|
      assign_to = assign_to.where(v)
    end

    group_by_assign = assign_to
                          .where("aggregations.today = (select max(today) from aggregations where project_id=#{where[0][1]})")
                          .group(:assigned_to_id)
    group_by_today = assign_to.group(:today, :assigned_to_id).order('today ASC')

    return group_by_assign, group_by_today

  end

  def self.get_date(where)

    data = self.select('min(start_date) as start_date','max(due_date) as due_date')
               .where("aggregations.today = (select max(today) from aggregations where project_id=#{where[0][1]})")
    where.each do |v|
      data = data.where(v)
    end

    data = data.limit(1)

    start_date = data.length > 0 ? data[0].start_date : nil
    due_date = data.length > 0 ? data[0].due_date : nil

    return start_date, due_date

  end

  def self.get_assigned_by_process(where)

    data = self.select(
        "concat(users.firstname,' ',users.lastname) as name",
        'aggregations.issue_id as issue_id',
        'aggregations.project_id as project_id',
        'aggregations.progress as progress',
        'aggregations.subject as subject')
               .joins('left join users on users.id = aggregations.assigned_to_id')
               .where('aggregations.progress > 0')

    where.each do |v|
      data = data.where(v)
    end

    data = data.order("name")

    return data

  end

end
