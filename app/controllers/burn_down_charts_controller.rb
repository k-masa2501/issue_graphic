include MyUtility
include BurnDownChartsHelper
class BurnDownChartsController < ApplicationController
  unloadable
  menu_item :redmine_chart
  before_filter :find_project, :authorize, :find_version, :set_filter, :set_master



  def index

    respond_to do |format|
      format.html{

        # プロジェクトに所属するメンバー

        @send_data = collect_graph_data

        @send_data[:member] = MyUtility.get_project_menber(@project.id, params)

        @send_data[:daily_aggs] = collect_daily_aggs

        @send_data[:day_names] = @day_names

        @js_labels = I18n.t('burn_down_charts.js')

      }
      format.zip {
=begin
        require 'zip'
        require 'stringio'

        report = Spreadsheet::Workbook.new
        info = report.create_worksheet :name => 'User Information'
        info.row(0).push 'User ID', 1,222,333,"ああああああキタジマ匡訓"

        outfile = "Report_for_#{1}.xls"

        data = StringIO.new ''

        report.write data

        new_data = Zip::OutputStream.write_buffer((StringIO.new '').set_encoding(Encoding::CP932),
                                                  Zip::TraditionalEncrypter.new('1234')) do |out|
          out.put_next_entry(outfile.encode(Encoding::CP932))
          out.write data.string
        end

        send_data new_data.string, :type => 'application/zip',
                  :disposition => 'attachment',
                  :filename => "#{outfile}.zip"
=end

        file_name = "Aggregation_#{Date.today.strftime("%Y-%m-%d")}"

        zipData = store_data_with_encryptZip(
          Aggregation.store_allRecord_with_excelData,
          "#{file_name}.xls",
          '1234'
        )

        send_data zipData.string, :type => 'application/zip',
                  :disposition => 'attachment',
                  :filename => "#{file_name}.zip"

      }
    end

  end

  def store_data_with_encryptZip(data, filename, encrypt, encoding=Encoding::CP932)
    require 'zip'
    Zip::OutputStream.write_buffer((StringIO.new '').set_encoding(encoding),
                                   Zip::TraditionalEncrypter.new(encrypt)) do |out|
      out.put_next_entry(filename.encode(encoding))
      out.write data.string
    end
  end

  def get_process

    subjects = Hash.new
    result = Aggregation.get_progress_each_assigned(@filter)
    Issue.where(id: result.pluck("issue_id")).pluck('id, subject').each do |v|
      subjects[v[0]] =  v[1]
    end

    render json: [{:method => 'obj_after',:value => render_to_string(partial: "burn_down_charts/index_t/process",
                                            locals: {contents: result.order("user_name"), subject: subjects, cells: params[:cells]} )}]

  end

  def get_burn_down_data

    data = collect_graph_data

    data[:member] = MyUtility.get_project_menber(@project.id, params)

    data[:daily_aggs] = collect_daily_aggs

    data[:day_names] = @day_names

    data[:render_table] = render_to_string(partial: "burn_down_charts/index_t/table",:locals => {:data => data} )
    data[:render_summary] = cell("cells/filter").(:sum, {project_id: @project.id,
                                                         params: params, filter: @filter,
                                                         member: data[:member]})
    data[:render_assigned_summary] = cell("cells/filter").(:sum_assigned, {project_id: @project.id,
                                                         params: params, filter: @filter,
                                                         member: data[:member]})

    render json: [{:method => 'done',:data => data}]

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

  def collect_graph_data
    begin

      estimated = Array.new
      atual = Array.new
      plan = Array.new
      daily_gap = Array.new

      data = Aggregation.get_aggs_each_daily(@filter)
      # データが存在しない場合は処理しない
      return {:estimated => nil, :atual => nil, :plan => nil, :daily_gap => nil} if data.length <= 0

      data.each_with_index do |v, i|
        estimated.push({date: v.today, value: v.estimated_sum})
        atual.push({date: v.today, value: v.estimated_sum - v.actual_sum})
        plan.push({date: v.today, value:v.estimated_sum - v.plan_value_sum})
        daily_gap.push(v.actual_sum - v.plan_value_sum)
      end
      start_date, due_date = Aggregation.get_both_date(@filter)

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

      return {:estimated => estimated, :atual => atual, :plan => plan, :daily_gap => daily_gap}
    rescue => e
      logger.error($@)
      logger.error(e.message)

      return {:estimated => nil, :atual => nil, :plan => nil, :daily_gap => nil}
    end

  end

  def collect_daily_aggs

    array = Array.new
    daily_aggs =  Array.new

    group_by_today = Aggregation.get_aggs_each_daily_assigned(@filter)

    today = group_by_today[0].today if group_by_today.length > 0

    group_by_today.each_with_index do |v, index|

      if today != v.today
        daily_aggs.push(array)
        array = Array.new
        today = v.today
      end

      array.push({name: v.name, sum: v.progress})

    end

    if group_by_today.length > 0
      daily_aggs.push(array)
    end

    return daily_aggs

  end

  def set_filter
    @filter = MyUtility.set_filter(params, @project.id)
  end

  def set_master
    @day_names = [
        I18n.t('burn_down_charts.sun'),
        I18n.t('burn_down_charts.mon'),
        I18n.t('burn_down_charts.tue'),
        I18n.t('burn_down_charts.wed'),
        I18n.t('burn_down_charts.thu'),
        I18n.t('burn_down_charts.fri'),
        I18n.t('burn_down_charts.sat')
    ]
  end

end
