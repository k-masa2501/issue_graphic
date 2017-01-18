include MyUtility
include StackedBarChartsHelper
class StackedBarChartsController < ApplicationController
  unloadable
  menu_item :redmine_chart
  before_filter :find_project, :authorize, :set_filter

  def index
    params[:f_view_point] ||= "assigned_to"
    params[:f_method] ||= "sum_act_value"
    params[:f_kind] ||= "weekly"

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

    render json: [{:method => 'done',:data => send}]

  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def collect_graph_data(params)

    sum = 0
    count = 0
    chart_data = Array.new

    data = Aggregation.get_sum_each_period_data(@filter, get_map(params[:f_view_point], params[:f_method], params[:f_kind]))

    before_date = data[:data][0][0] if 0 < data[:data].length

    procedure = ->(v, keys, chart_data, sum, count, before_date, params){

      if v[0] != before_date
        tmp_sum = 0
        keys.each do |v|
          if chart_data[count][v].blank?
            chart_data[count][v] = 0
          end
          tmp_sum += chart_data[count][v]
        end
        sum = tmp_sum if sum < tmp_sum
        count += 1
      end

      return chart_data, sum, count

    }

    data[:data].each_with_index do |v,i|

      chart_data, sum, count = procedure.call(v, data[:keys], chart_data, sum, count, before_date, params)

      before_date = v[0]
      chart_data[count] ||= Hash.new
      chart_data[count][v[1]] = v[2].to_i
      if "weekly" == params[:f_kind]
        chart_data[count]['date'] ||= get_weekly_first_date(v[0])
      else
        chart_data[count]['date'] ||= v[0]
      end

    end

    chart_data, sum, count =
        procedure.call(data[:data][data[:data].length-1], data[:keys], chart_data, sum, count, nil, params) if 0 < data[:data].length

    return {:data => chart_data, :keys => data[:keys], :sum => sum}
  end

  def set_filter
    @filter = MyUtility.set_filter(params, @project.id)
  end

  def get_weekly_first_date(date)

    obj = Date.parse(date)
    return (obj - obj.wday).strftime("%Y-%m-%d")

  end

  def get_map(view, method, kind)

    result = nil
    method_map = Hash.new
    kind_map = Hash.new

    view_map = {
        'assigned_to' => {:joins => :assigned_to, :pluck => "concat(firstname,' ', lastname)"},
        'tracker' => {:joins => :tracker, :pluck => "name"},
        'status' => {:joins => :status, :pluck => "name"},
        'priority' => {:joins => :priority, :pluck => "name"},
        'category' => {:joins => :category, :pluck => "name"},
        'fixed_version' => {:joins => :fixed_version, :pluck => "name"}
    }

    if view_map[view].present?

      method_map["sum_act_value"] = {:query => "sum(aggregations.act_value)"}
      method_map["count_act_value"] = {:query => "sum(case when aggregations.act_value > 0 then 1 else 0 end)"}

      if method_map[method].present?

        kind_map["daily"] = {:group => "%Y%m%d", :pluck => "%Y-%m-%d"}
        kind_map["weekly"] = {:group => "%Y%U", :pluck => "%Y-%m-%d"}
        kind_map["monthly"] = {:group => "%Y%m", :pluck => "%Y-%m"}

        result = {:view => view_map[view], :method => method_map[method], :format => kind_map[kind]} if kind_map[kind].present?

      end

    end

    return result

  end

end
