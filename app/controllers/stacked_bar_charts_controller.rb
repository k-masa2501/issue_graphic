include MyUtility
include StackedBarChartsHelper
class StackedBarChartsController < ApplicationController
  unloadable
  menu_item :redmine_chart
  before_filter :find_project, :authorize, :set_filter

  def index

    params[:f_view_point] ||= "assigned_to"
    params[:f_method] ||= "sum_act_value"
    params[:f_kind] ||= "daily"
    params[:f_week_cnt] ||= "10"
    params[:f_d_start] ||= (Date.today-30).strftime("%Y/%m/%d")
    params[:f_d_end] ||= params[:f_w_end] ||= Date.today.strftime("%Y/%m/%d")

    @chart_data = collect_graph_data(params)

    # プロジェクトに所属するメンバー
    @member = MyUtility.get_project_menber(@project.id, params)

  end

  def get_stacked_bar_chart_data

    send = Hash.new

    send[:data] = collect_graph_data(params)

    member = MyUtility.get_project_menber(@project.id, params)

    send[:render_summary] = cell("cells/filter").(:sum, {project_id: @project.id,
                                                         params: params, filter: @filter,
                                                         member: member})
    send[:type] = params[:f_method]

    render json: [{:method => 'done',:data => send}]

  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def collect_graph_data(params)

    result = nil

    case params[:f_kind]
      when 'daily' then
        result = daily_data(params)
      when 'weekly' then
        result = weekly_data(params)
      when 'monthly' then
        result = monthly_data(params)
      else
    end

    return result

  end

  def daily_data(params)

    result = {}

    # 日の収集
    days = correction_days(params)

    factor = {:f =>  '%Y/%m/%d', :d => days}

    case params[:f_method]
      when 'sum_act_value' then # 消化工数の推移
        result = data_formalize(trend_of_total_progress(days, get_map(params), factor[:f]), factor)
      when 'count_act_value' then # 消化件数の推移
        result = data_formalize(trend_of_total_count(days, get_map(params), factor[:f]), factor)
      when 'ticket_amount' then  # チケット量の推移
        result = data_formalize(ticket_amount(days, get_map(params), factor[:f]), factor)
      when 'workload' then # 作業量の推移
        result = data_formalize(workload(days, get_map(params), factor[:f]), factor)
      when 'per_period_work' then # 期間ごとの作業量
        result = data_formalize(per_period_work_day(days, get_map(params), factor[:f]), factor)
      when 'per_period_oc' then # 期間ごとの発生/クローズ件数
        result = data_formalize_period(per_period_oc_day(days, get_map(params), factor[:f]))
      else
    end

    return result

  end

  def weekly_data(params)

    result = {}

    # 週の収集
    days = correction_weeks(params)

    factor = {:f =>  '%Y/%m/%d', :d => days}

    case params[:f_method]
      when 'sum_act_value' then # 消化工数の推移
        result = data_formalize_week(trend_of_total_progress(days, get_map(params), factor[:f]), factor)
      when 'count_act_value' then # 消化件数の推移
        result = data_formalize_week(trend_of_total_count(days, get_map(params), factor[:f]), factor)
      when 'ticket_amount' then  # チケット量の推移
        result = data_formalize_week(ticket_amount(days, get_map(params), factor[:f]), factor)
      when 'workload' then # 作業量の推移
        result = data_formalize_week(workload(days, get_map(params), factor[:f]), factor)
      when 'per_period_work' then # 単位ごとの作業量
        result = data_formalize_week(per_period_work_week(days, get_map(params), factor[:f]), factor)
      when 'per_period_oc' then # 期間ごとの発生/クローズ件数
        result = data_formalize_period_week(per_period_oc_week(days, get_map(params), factor[:f]), factor)
      else
    end

    return result

  end

  def monthly_data(params)

    result = {}

    # 月の補正
    days = correction_endMonths(params)

    factor = {:f =>  '%Y/%m', :d => days}

    case params[:f_method]
      when 'sum_act_value' then # 消化工数の推移
        result = data_formalize(trend_of_total_progress(days, get_map(params), factor[:f]), factor)
      when 'count_act_value' then # 消化件数の推移
        result = data_formalize(trend_of_total_count(days, get_map(params), factor[:f]), factor)
      when 'ticket_amount' then  # チケット量の推移
        result = data_formalize(ticket_amount(days, get_map(params), factor[:f]), factor)
      when 'workload' then # 作業量の推移 workload
        result = data_formalize(workload(days, get_map(params), factor[:f]), factor)
      when 'per_period_work' then # 単位ごとの作業量
        result = data_formalize(per_period_work_month(days, get_map(params), factor[:f]), factor)
      when 'per_period_oc' then # 期間ごとの発生/クローズ件数
        result = data_formalize_period(per_period_oc_month(correction_startMonths(params), get_map(params), factor[:f]))
      else
    end

    return result

  end

  def trend_of_total_progress(days, map, format)
    return Aggregation.trend_of_total_progress(@filter, days, map, format)
  end

  def trend_of_total_count(days, map, format)
    return Aggregation.trend_of_total_count(@filter, days, map, format)
  end

  def ticket_amount(days, map, format)
    return Aggregation.ticket_amount(@filter, days, map, format)
  end

  def workload(days, map, format)
    return Aggregation.workload(@filter, days, map, format)
  end

  def per_period_work(days, map, format, condition)
    return Aggregation.per_period_work(@filter, days, map, format, condition)
  end

  def per_period_work_day(days, map, format)
    condition = ->(v){
      return "aggregations.today = #{v}"}
    per_period_work(days, map, format, condition)
  end

  def per_period_work_week(days, map, format)
    condition = ->(v){
      return "aggregations.today BETWEEN '#{Date.parse(v)-6}' AND #{v}"}
    per_period_work(days, map, format, condition)
  end

  def per_period_work_month(days, map, format)
    condition = ->(v){
      return "aggregations.today BETWEEN '#{Date.parse(v).beginning_of_month}' AND '#{(Date.parse(v))}'"}
    per_period_work(days, map, format, condition)
  end

  def per_period_oc(days, map, format, condition)
    record = RedmineChartIssue.per_period_oc(@filter, days, map, format, condition)
  end

  def per_period_oc_day(days, map, format)

    condition = ->(v){
      fmt = '%Y/%m/%d %H:%M:%S'
      return "BETWEEN '#{DateTime.parse(v+' 00:00:00').strftime(fmt)}' and '#{DateTime.parse(v+' 23:59:59').strftime(fmt)}'"
    }
    per_period_oc(days, map, format, condition)

  end

  def per_period_oc_week(days, map, format)

    condition = ->(v){
      fmt = '%Y/%m/%d %H:%M:%S'
      return "BETWEEN '#{(DateTime.parse(v+' 00:00:00')-6).strftime(fmt)}' and '#{DateTime.parse(v+' 23:59:59').strftime(fmt)}'"
    }
    per_period_oc(days, map, format, condition)

  end

  def per_period_oc_month(days, map, format)

    condition = ->(v){
      fmt = '%Y/%m/%d %H:%M:%S'
      return "BETWEEN '#{DateTime.parse(v+' 00:00:00').strftime(fmt)}' and '#{DateTime.parse(v+' 23:59:59').end_of_month.strftime(fmt)}'"
    }
    per_period_oc(days, map, format, condition)

  end

  def correction_days(params)

    days = Array.new
    start_date = Date.parse(params[:f_d_start])
    end_date = Date.parse(params[:f_d_end])

    (start_date..end_date).each do |v|
      days.push("'#{v.strftime("%Y-%m-%d")}'")
    end

    days.push("'1970-1-1'") if 0 >= days.length

    return days

  end

  def correction_weeks(params)

    days = Array.new
    end_date = Date.parse(params[:f_w_end])

    for num in 0..(params[:f_week_cnt].to_i-1)
      days.unshift("'#{(end_date-(num*7)).strftime("%Y-%m-%d")}'")
    end

    days.push("'1970-1-1'") if 0 >= days.length

    return days

  end

  def correction_startMonths(params)

    days = Array.new
    start_date = Date.parse(params[:f_m_start]).end_of_month
    end_date = Date.parse(params[:f_m_end]).end_of_month

    while start_date <= end_date
      days.push("'#{start_date.beginning_of_month.strftime("%Y-%m-%d")}'")
      start_date = start_date >> 1
    end

    days.push("'1970-1-1'") if 0 >= days.length

    return days

  end

  def correction_endMonths(params)

    days = Array.new
    start_date = Date.parse(params[:f_m_start]).end_of_month
    end_date = Date.parse(params[:f_m_end]).end_of_month

    while start_date <= end_date
      days.push("'#{start_date.end_of_month.strftime("%Y-%m-%d")}'")
      start_date = start_date >> 1
    end

    days.push("'1970-1-1'") if 0 >= days.length

    return days

  end

  def data_formalize(data, factor=nil)

    count = 0
    chart_data = Array.new

    if factor.present?

      tmpData = Array.new
      0 < data[:data].length and factor[:d].each do |v1|

        if 0 < (v2 = data[:data].select {|v2| Date.parse(v1).strftime(factor[:f]) == Date.parse(v2[0]).strftime(factor[:f]) }).length
          v2.each do |v3|
            tmpData.push([v3[0], v3[1], v3[2]])
          end
        else
          tmpData.push([Date.parse(v1).strftime(factor[:f]), data[:keys][0], 0])
        end

      end

    else

      tmpData = data[:data]

    end

    tmpData.each_with_index do |v,i|

      chart_data[count] ||= Hash.new
      chart_data[count][v[1]] = v[2].to_i
      chart_data[count][:date] ||= v[0]

      if tmpData.length <= i+1 || tmpData[i+1][0] != v[0]

        data[:keys].each do |v|
          if chart_data[count][v].blank?
            chart_data[count][v] = 0
          end
        end
        count += 1

      end

    end

    return {:data => chart_data, :keys => data[:keys]}
  end

  def data_formalize_week(data, factor)

    result = data_formalize(data, factor)

    result[:data].each do |v|
      v[:date] = (Date.parse(v[:date])-6).strftime(factor[:f]) + '-' + Date.parse(v[:date]).strftime('%m/%d')
    end

    return result

  end

  def data_formalize_period_week(data, factor)

    result = data_formalize_period(data)

    result[:d].each do |k,val|
      val[:data].each do |v|
        v[:date] = (Date.parse(v[:date])-6).strftime(factor[:f]) + '-' + Date.parse(v[:date]).strftime('%m/%d')
      end
    end

    result[:diff].each do |v|
      v[:date] = (Date.parse(v[:date])-6).strftime(factor[:f]) + '-' + Date.parse(v[:date]).strftime('%m/%d')
    end

    return result

  end

  def data_formalize_period(data)

    result = {:d => Hash.new, :k1 => Hash.new}
    data[:keys1].each do |k,v|
      result[:d][k] = data_formalize({:data => data[:data][k], :keys => data[:keys2]})
      result[:k1][k] = v
    end

    result[:k2] = data[:keys2]
    result[:diff] = data[:diff]

    return result

  end


  def set_filter
    @filter = MyUtility.set_filter(params, @project.id)
  end

  def get_weekly_first_date(date)

    obj = Date.parse(date)
    return (obj - obj.wday).strftime("%Y-%m-%d")

  end

  def get_map(params)

    view_map = {
        'assigned_to' => {:joins => :assigned_to, :pluck => "concat(lastname,' ',firstname)"},
        'tracker' => {:joins => :tracker, :pluck => "name"},
        'status' => {:joins => :status, :pluck => "name"},
        'priority' => {:joins => :priority, :pluck => "name"},
        'category' => {:joins => :category, :pluck => "name"},
        'fixed_version' => {:joins => :fixed_version, :pluck => "name"}
    }

    return {:view => view_map[params[:f_view_point]]}

  end

end
