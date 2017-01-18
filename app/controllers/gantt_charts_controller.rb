include MyUtility
include GanttChartsHelper
class GanttChartsController < ApplicationController
  unloadable
  menu_item :redmine_chart
  before_filter :find_project, :authorize, :find_version, :set_filter

  def index

    @chart_data = collect_gantt_chart_data

  end

  def get_gantt_chart_data

    send = Hash.new

    send[:data] = collect_gantt_chart_data

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

  def find_version
    version = Version.where("project_id = ?", @project.id)
    option = {:message => I18n.t('burn_down_charts.version_not exist')}
    render_404(option) if 0 >= version.length
  end

  def collect_gantt_chart_data

    pos = 0
    chart_data = Array.new
    is_closed = IssueStatus.where('is_closed > 0').pluck('id')
    max = Date.parse('2000-01-01')
    min = Date.parse('2099-01-01')

    RedmineChartIssue.get_progress_total_rate(@filter).each_with_index do |v,i|
      # 開始日と終了日がない場合はそれぞれ初期値を投入
      v.start_date ||= Date.today
      v.due_date ||= v.start_date + 10
      v.estimated ||= 0
      v.act_rate ||= 0

      # 残日数
      r_day = v.due_date - (v.start_date-1)
      average = v.estimated.quo(r_day.to_i)
      act = v.act_rate.quo(average.to_f)

      chart_data[i] = [Hash.new,Hash.new]
      chart_data[i][0][:href] = nil
      chart_data[i][1][:href] = nil
      chart_data[i][0][:text] = "合計)" + v.estimated.round(1).to_s + "h/"
      chart_data[i][0][:text] += v.act_rate.round(1).to_s + "h/" + v.rem_rate.round(1).to_s + "h"
      chart_data[i][1][:text] = ""
      chart_data[i][0][:data] = r_day.to_i*24
      chart_data[i][1][:data] = act.to_f*24
      chart_data[i][0][:pos] =  pos
      chart_data[i][1][:pos] =  pos
      chart_data[i][0][:color] =  "#DFDFDF"
      chart_data[i][1][:color] =  gantt_color(v, is_closed)
      chart_data[i][0][:date] =  v.start_date.to_s + " 00:00"
      chart_data[i][1][:date] =  v.start_date.to_s + " 00:00"
      pos +=30
    end

    RedmineChartIssue.get_task_progress_rate(@filter).each_with_index do |v,i|

      # 開始日と終了日がない場合はそれぞれ初期値を投入
      v.start_date ||= Date.today
      v.due_date ||= v.start_date + 10

      # 残日数
      r_day = v.due_date - (v.start_date-1)
      average = v.estimated.quo(r_day.to_i)
      act = v.act_rate.quo(average.to_f)

      chart_data.push([Hash.new,Hash.new])
      aP = chart_data.length-1
      chart_data[aP][0][:href] = issue_path(v.id)
      chart_data[aP][1][:href] = issue_path(v.id)
      chart_data[aP][0][:text] = v.name + ")" + v.subject.to_s
      chart_data[aP][1][:text] = ""
      chart_data[aP][0][:data] = (r_day*24).to_i
      chart_data[aP][1][:data] = (act*24).to_f
      chart_data[aP][0][:pos] =  pos
      chart_data[aP][1][:pos] =  pos
      chart_data[aP][0][:color] =  "#DFDFDF"
      chart_data[aP][1][:color] =  gantt_color(v, is_closed)
      chart_data[aP][0][:date] =  v.start_date.to_s + " 00:00"
      chart_data[aP][1][:date] =  v.start_date.to_s + " 00:00"
      pos +=30

      min = v.start_date if min > v.start_date
      max = v.due_date if max < v.due_date

    end
    return {:data => chart_data, :start_date => min.to_s+" 00:00", :due_date => (max+1).to_s+" 00:00"}
  end

  def set_filter
    @filter = MyUtility.set_filter(params, @project.id)
  end

end
