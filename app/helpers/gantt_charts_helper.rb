module GanttChartsHelper

  def gantt_color(v, is_closed)

    r_day = v.due_date - v.start_date
    average = v.estimated.quo(v.due_date - (v.start_date-1))
    if v.due_date < Date.today
      now = r_day
    else
      now = Date.today - v.start_date
    end

    if  is_closed.find {|n| n.to_i == v.status_id.to_i}
      '#89d6e2' # is_closed
    elsif v.act_rate < now*average
      '#FF727B' # delayed
    else
      '#a5e899' # as scheduled
    end

  end
end
