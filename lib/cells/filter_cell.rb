class Cells::FilterCell <  Cell::ViewModel

  include ActionView::Helpers::TranslationHelper
  include Cell::Translation

  # form 関連
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  include ::Cell::Haml

  include MyUtility

  self.view_paths << "plugins/redmine_chart/lib"

  def filter(args)

    # プロジェクトに所属するメンバー
    @assigned_to = Member.joins(:user)
                       .where(project_id: args[:project_id])
                       .pluck("concat(users.firstname,' ',users.lastname) as name, users.id")

    # トラッカー
    @tracker = Tracker
                   .joins('inner join projects_trackers ptrs on trackers.id = ptrs.tracker_id')
                   .where('ptrs.project_id = ?', args[:project_id])
                   .pluck('trackers.name, trackers.id')

    # ステータス
    @status = IssueStatus.pluck('name, id')

    # 優先度
    @priority = Enumeration.where('type = ?',IssuePriority).pluck('name, id')

    # カテゴリ
    @category = IssueCategory.where('project_id = ?', args[:project_id]).pluck('name, id')

    # version
    @version = Version.where('project_id = ?', args[:project_id]).pluck('name, id')

    render
  end

  def sum(args)

    args[:member] ||= MyUtility.get_project_menber(args[:project_id], args[:params])

    @act_total, @count_total = collect_assigned_total(args[:member], args[:filter])

    render
  end

  def timeSeries_filter
    @view_point = [[I18n.t('cells.filter.assigned_to'), "assigned_to"],
                   [I18n.t('cells.filter.tracker'), "tracker"],
                   [I18n.t('cells.filter.status'), "status"],
                   [I18n.t('cells.filter.priority'), "priority"],
                   [I18n.t('cells.filter.category'), "category"],
                   [I18n.t('cells.filter.version'), "fixed_version"]]
    @method = [[I18n.t('cells.filter.progress_total'), "sum_act_value"],
               [I18n.t('cells.filter.rem_work'), "sum_rem_act_value"],
               [I18n.t('cells.filter.number_of_initiations'), "count_act_value"],
               [I18n.t('cells.filter.number_of_rem_items'), "count_rem_act_value"]]
    render
  end

  def stackBar_filter
    @view_point = [[I18n.t('cells.filter.assigned_to'), "assigned_to"],
                   [I18n.t('cells.filter.tracker'), "tracker"],
                   [I18n.t('cells.filter.status'), "status"],
                   [I18n.t('cells.filter.priority'), "priority"],
                   [I18n.t('cells.filter.category'), "category"],
                   [I18n.t('cells.filter.version'), "fixed_version"]]
    @method = [[I18n.t('cells.filter.progress_total'), "sum_act_value"],
               [I18n.t('cells.filter.number_of_initiations'), "count_act_value"],
               [I18n.t('cells.filter.ticket_amount'), "ticket_amount"],
               [I18n.t('cells.filter.workload'), "workload"],
               ['クローズ件数', "close"],
               [I18n.t('cells.filter.per_unit'), "per_unit"]]
    @kind = [['日', "daily"],['週', "weekly"],['月', "monthly"]]
    @months = Array.new

    for num in 0..36
      @months.push((Date.today << num).strftime("%Y/%m"))
    end
    render
  end

  private

  ## form_for の返り値が escape されてしまうので override
  def form_for(model, options, &block)
    raw(super)
  end

  def custom_options_for_select(array, default=nil)
    array.unshift([I18n.t('burn_down_charts.unselected'),nil])
    options_for_select(array, default)
  end

  def collect_assigned_total(memer, filter)

    act_total = get_act_total(memer, filter)

    count_total = get_count_total(memer, filter)

    return act_total, count_total

  end

  def get_act_total(memer, filter)

    estimated = Array.new
    remaining = Array.new

    act_total = RedmineChartIssue.get_total_each_assigned(filter)

    memer.each do |v|
      item = act_total.find { |item| item.name == v[0] }
      if nil != item
        estimated_tmp = item.estimated_total.round(1)
        remaining_tmp = item.remaining_total.round(1)
        estimated.push([item.name, estimated_tmp])
        remaining.push([item.name, remaining_tmp])
      else
        estimated.push([v[0], 0])
        remaining.push([v[0], 0])
      end
    end

    estimated_total =0
    remaining_total =0

    RedmineChartIssue.get_total_each_fixedVersion(filter).each do |v|
      estimated_total = v.estimated_total
      remaining_total = v.remaining_total
    end

    estimated.unshift([I18n.t('cells.filter.total'), estimated_total.round(1)])
    remaining.unshift([I18n.t('cells.filter.total'), remaining_total.round(1)])

    return {:estimated => estimated, :remaining => remaining }

  end

  def get_count_total(memer, filter)

    estimated = Array.new
    remaining = Array.new
    estimated_total = 0
    remaining_total = 0

    count_total = RedmineChartIssue.get_count_each_assigned(filter)

    memer.each do |v|
      item = count_total.find { |item| item.name == v[0] }
      if nil != item
        count_total_tmp = item.count_total.round(0)
        count_tmp = item.count.round(0)
        estimated.push([item.name, count_total_tmp])
        remaining.push([item.name, count_tmp])
        estimated_total += count_total_tmp
        remaining_total += count_tmp
      else
        estimated.push([v[0], 0])
        remaining.push([v[0], 0])
      end
    end

    estimated.unshift([I18n.t('cells.filter.total'), estimated_total.round(0)])
    remaining.unshift([I18n.t('cells.filter.total'), remaining_total.round(0)])

    return {:estimated => estimated, :remaining => remaining}

  end

end
