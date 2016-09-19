class IssueGraphicsController < ApplicationController
  unloadable
  menu_item :issue_graphic
  before_filter :find_project, :authorize
  before_filter :find_issue_graphic, :except => [:index, :get_process]

  def index

    set_filter(params)

    @day_names = [
        I18n.t('issue_graphics.sun'),
        I18n.t('issue_graphics.mon'),
        I18n.t('issue_graphics.tue'),
        I18n.t('issue_graphics.wed'),
        I18n.t('issue_graphics.thu'),
        I18n.t('issue_graphics.fri'),
        I18n.t('issue_graphics.sat')
    ]

    # トラッカー
    @tracker = Tracker
                     .joins('inner join projects_trackers ptrs on trackers.id = ptrs.tracker_id')
                     .where('ptrs.project_id = ?', @project.id)
                     .pluck('trackers.name, trackers.id')

    # ステータス
    @status = IssueStatus.pluck('name, id')
    @status.unshift([I18n.t('issue_graphics.incomplete'),9999])

    # 優先度
    @priority = Enumeration.where('type = ?',IssuePriority).pluck('name, id')

    # カテゴリ
    @category = IssueCategory.where('project_id = ?', @project.id).pluck('name, id')

    # カスタムフィールド
    @custom = get_custom_enumerations(@project.id)

    # プロジェクトに所属するメンバー
    @member = Member.joins(:user)
                  .where(project_id: @project.id)
                  .pluck("concat(users.firstname,' ',users.lastname) as name, users.id")

    @assigned_to = Marshal.load(Marshal.dump(@member))

    @member.push([nil,nil])

    @member = [@member.find { |v| v[1].to_i == params[:f_assigned_to].to_i}] if params[:f_assigned_to].present?

    # プロジェクトごとの集計結果を取得
    data = Aggregation.get_sum_group_by_today(@index_filter)
    @estimated, @atual, @plan, @daily_gap = collect_graph_data(data)

    # 担当者別日ごとの実績値
    @daily_sum, @total_by_assigned, @progress = get_every_assigned_in_charge_act(@member)

  end

  def get_process
    set_filter(params)
    result = Aggregation.get_assigned_by_process(@index_filter)
    render json: {:html => render_to_string(partial: "issue_graphics/index_t/process",
                                            locals: {contents: result, cells: params[:cells]} )}
  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_ticket_graphic
    #@foo = Foo.find_by_id(params[:id])
    #render_404    unless @foo
  end


  def collect_graph_data(data)
    #begin

    estimated = Array.new
    atual = Array.new
    plan = Array.new
    daily_gap = Array.new

    # データが存在しない場合は処理しない
    return nil, nil, nil, nil if data.length <= 0

    # チケットの期限が一番遅い日と、開始日が一番早い日を取得
    start_date, due_date = Aggregation.get_date(@index_filter)

    data.each_with_index do |v, i|
      estimated.push({date: v.today, value: v.estimated_sum})
      atual.push({date: v.today, value: v.estimated_sum - v.actual_sum})
      plan.push({date: v.today, value:v.estimated_sum - v.plan_value_sum})
      daily_gap.push(v.actual_sum - v.plan_value_sum)
    end

    #r_average = plan[plan.length-1][:value].quo(due_date - data[data.length-1].today)
    count = 0
    ((data[data.length-1].today+1)..due_date).each_with_index do |v, i|
      next if v.wday == 0 or v.wday == 6 or v < start_date
      count += 1
    end

    r_average = plan[plan.length-1][:value].quo(count)

    ((data[data.length-1].today+1)..due_date).each_with_index do |v, i|
      estimated.push({date: v, value: data[data.length-1].estimated_sum})
      if v.wday == 0 or v.wday == 6 or v < start_date
        plan.push({date: v, value:plan[plan.length-1][:value]})
      else
        plan.push({date: v, value:plan[plan.length-1][:value] - r_average})
      end
    end

    # planの最後は0
    plan[plan.length-1]['value'] = 0

    return estimated, atual, plan, daily_gap

    #rescue => e
    #logger.error($@)
    #logger.error(e.message)
    #return 0, nil, nil, nil
    #end

  end

  def get_every_assigned_in_charge_act(memer)

    array = Array.new
    daily_sum =  Array.new

    group_by_assign, group_by_today = Aggregation.get_assign_act_cost(@index_filter)

    today = group_by_today[0].today if group_by_today.length > 0

    group_by_today.each_with_index do |v, index|

      if today != v.today
        daily_sum.push(array)
        array = Array.new
        today = v.today
      end

      array.push({name: v.name, sum: v.progress})

    end

    if group_by_today.length > 0
      daily_sum.push(array)
    end

    total_by_assigned = Array.new
    progress = Array.new

    memer.each do |v|
      item = group_by_assign.find {|item| item.name == v[0] }
      if nil != item
        total_by_assigned.push([item.name, item.estimated_sum.round(1)])
        progress.push([item.name, item.actual_sum.round(1)])
      else
        total_by_assigned.push([v[0], 0.0])
        progress.push([v[0], 0.0])
      end
    end

    return daily_sum, total_by_assigned, progress

  end

  def get_issues_date(where)

    cf_t = CustomField.arel_table

    data = Issue.select(
        'min(issues.start_date) as start_date',
        'max(issues.due_date) as due_date')
        .joins('LEFT JOIN custom_values on issues.id = custom_values.customized_id')
        .joins('LEFT JOIN custom_fields on custom_values.custom_field_id = custom_fields.id')
        .where(cf_t[:field_format].eq('enumeration').or(cf_t[:field_format].eq(nil)))
        .where(cf_t[:type].eq('IssueCustomField').or(cf_t[:type].eq(nil)))
    where.each do |v|
      data = data.where(v)
    end

    return data[0].start_date, data[0].due_date

  end

  def set_filter(params)

    @index_filter = [['aggregations.project_id = ?',@project.id]]

    params.each do |key,value|
      case key
        when 'custom' then
          value.each do |k2,v2|
            @index_filter.push(["aggregations.custom_value REGEXP '(^|,)?=?(,|$)'", k2.to_i,v2.to_i]) if v2.present?
          end
        when 'f_assigned_to' then
          @index_filter.push(["aggregations.assigned_to_id = ?", value]) if value.present?
        when 'f_tracker' then
          @index_filter.push(["aggregations.tracker_id = ?", value]) if value.present?
        when 'f_priority' then
          @index_filter.push(["aggregations.priority_id = ?", value]) if value.present?
        when 'f_category' then
          @index_filter.push(["aggregations.category_id = ?", value]) if value.present?
        when 'f_status' then
          if value.to_i == 9999
            @index_filter.push(["aggregations.status_id in (select id from issue_statuses where is_closed = 0)"])
          else
            @index_filter.push(["aggregations.status_id = ?", value]) if value.present?
          end
        when 'today' then
          @index_filter.push(["aggregations.today = ?", value]) if value.present?
        else
      end
    end


  end

  def get_custom_enumerations(project_id)

    cf_t = CustomField.arel_table

    record = CustomField.select(
        'custom_fields.id',
        'custom_fields.name as title',
        'enum.name',
        'enum.id as value')
                 .joins('INNER join custom_fields_projects cpro on custom_fields.id = cpro.custom_field_id')
                 .joins('INNER join custom_field_enumerations enum on custom_fields.id = enum.custom_field_id')
                 .where(cf_t[:field_format].eq('enumeration').or(cf_t[:field_format].eq(nil)))
                 .where(cf_t[:type].eq('IssueCustomField').or(cf_t[:type].eq(nil)))
                 .where('cpro.project_id = ?', project_id)

    if record.length > 0
      id = record[0].id
      title = record[0].title
    end

    enum = Array.new
    array = Array.new

    record.each_with_index  do |v, i|

      if id != v.id
        enum.unshift(id)
        array.push({title => enum})
        enum = Array.new
      end

      enum.push([v.name,v.value])
      id = v.id
      title = v.title

    end

    if record.length > 0
      enum.unshift(id)
      array.push({title => enum})
    end

    return array

  end

end
