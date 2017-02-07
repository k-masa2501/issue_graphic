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
    params[:f_d_start] ||= (Date.today-60).strftime("%Y/%m/%d")
    params[:f_d_end] ||= params[:f_w_end] ||= Date.today.strftime("%Y/%m/%d")

    @chart_data = collect_graph_data(params)

    logger.debug @chart_data

    # プロジェクトに所属するメンバー
    @member = MyUtility.get_project_menber(@project.id, params)

  end

  def get_stacked_bar_chart_data
    logger.debug "#{__method__} start"
    send = Hash.new

    send[:data] = collect_graph_data(params)

    member = MyUtility.get_project_menber(@project.id, params)

    send[:render_summary] = cell("cells/filter").(:sum, {project_id: @project.id,
                                                         params: params, filter: @filter,
                                                         member: member})

    render json: [{:method => 'done',:data => send}]
    logger.debug "#{__method__} end"
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def collect_graph_data(params)
    logger.debug "#{__method__} start"

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

    logger.debug "#{__method__} end"
    return result

  end

  def daily_data(params)
    logger.debug "#{__method__} start"

    result = nil
    
    # 日の収集
    days = correction_days(params)

    case params[:f_method]
      when 'sum_act_value' then # 進捗合計の推移
        result = data_formalize(trend_of_total_progress(days, get_map(params), '%Y/%m/%d'), days)
      when 'count_act_value' then # 着手件数の推移
      when 'ticket_amount' then  # チケット量の推移
      when 'workload' then # 作業量の推移
      when 'close' then # クローズ件数
      when 'per_unit' then # 単位ごとの作業量
      else
    end

    logger.debug "#{__method__} end"
    return result

  end

  def weekly_data(params)
    logger.debug "#{__method__} start"

    result = nil

    # 日の収集
    days = correction_weeks(params)

    case params[:f_method]
      when 'sum_act_value' then # 進捗合計の推移
        result = data_formalize(trend_of_total_progress(days, get_map(params), '%Y/%m/%d'), days)
      when 'count_act_value' then # 着手件数の推移
      when 'ticket_amount' then  # チケット量の推移
      when 'workload' then # 作業量の推移
      when 'close' then # クローズ件数
      when 'per_unit' then # 単位ごとの作業量
      else
    end

    logger.debug "#{__method__} end"
    return result

  end

  def monthly_data(params)
    logger.debug "#{__method__} start"

    result = nil

    # 月の補正
    days = correction_months(params)

    case params[:f_method]
      when 'sum_act_value' then # 進捗合計の推移
        result = data_formalize(trend_of_total_progress(days, get_map(params), '%Y/%m'), days)
      when 'count_act_value' then # 着手件数の推移
      when 'ticket_amount' then  # チケット量の推移
      when 'workload' then # 作業量の推移
      when 'close' then # クローズ件数
      when 'per_unit' then # 単位ごとの作業量
      else
    end

    logger.debug "#{__method__} end"
    return result

  end

  def trend_of_total_progress(days, map, format)
    logger.debug "#{__method__} days=#{days.to_s}, map=#{map.to_s}, start"
    
    query_var1 = "CASE WHEN #{map[:view][:pluck]} is NULL THEN 'null' ELSE #{map[:view][:pluck]} END"
    record = Aggregation.joins(map[:view][:joins])

    @filter.each do |v|
      query = [Aggregation.table_name + '.' + v[0],v[1]]
      record = record.where(query)
    end

    keys = record.pluck(query_var1).uniq
    data = record.where("today in (#{days.join(',')})")
                 .group("aggregations.today", query_var1)
                 .pluck(
                     "DATE_FORMAT(today,'#{format}')",
                     query_var1,
                     "sum(aggregations.act_value)",
                     "DATE_FORMAT(today,'%Y-%m-%d')",
                 )

    logger.debug "#{__method__} end"
    return {:data => data, :keys => keys}

  end

  def correction_days(params)

    days = Array.new
    start_date = Date.parse(params[:f_d_start])
    end_date = Date.parse(params[:f_d_end])
    
    (start_date..end_date).each do |v|
      days.push("'#{v.strftime("%Y-%m-%d")}'")
    end

    return days

  end

  def correction_weeks(params)

    days = Array.new
    end_date = Date.parse(params[:f_w_end])

    for num in 1..params[:f_week_cnt].to_i
      days.push("'#{(end_date-(num*7)).strftime("%Y-%m-%d")}'")
    end

    return days

  end

  def correction_months(params)

    days = Array.new
    start_date = Date.parse(params[:f_m_start]).end_of_month
    end_date = Date.parse(params[:f_m_end]).end_of_month

    while start_date <= end_date
      days.push("'#{start_date.end_of_month.strftime("%Y-%m-%d")}'")
      start_date = start_date >> 1
    end

    return days

  end

  def data_formalize(data, days)

    count = 0
    chart_data = Array.new

    data[:data].each_with_index do |v,i|

      chart_data[count] ||= Hash.new
      chart_data[count][v[1]] = v[2].to_i
      chart_data[count]['date'] ||= v[0]

      if data[:data].length <= i+1 || data[:data][i+1][0] != v[0]

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


  def set_filter
    @filter = MyUtility.set_filter(params, @project.id)
  end

  def get_weekly_first_date(date)

    obj = Date.parse(date)
    return (obj - obj.wday).strftime("%Y-%m-%d")

  end

  def get_map(params)

    view_map = {
        'assigned_to' => {:joins => :assigned_to, :pluck => "concat(firstname,' ', lastname)"},
        'tracker' => {:joins => :tracker, :pluck => "name"},
        'status' => {:joins => :status, :pluck => "name"},
        'priority' => {:joins => :priority, :pluck => "name"},
        'category' => {:joins => :category, :pluck => "name"},
        'fixed_version' => {:joins => :fixed_version, :pluck => "name"}
    }

    return {:view => view_map[params[:f_view_point]]}

  end

end
