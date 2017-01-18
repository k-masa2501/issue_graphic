module GanttChartsHelper

  def gantt_color(v, is_closed)

    #logger.debug(v.done_rate.to_f)

    r_day = v.due_date - (v.start_date-1)
    average = v.estimated.quo(r_day)
    #logger.debug(r_day.to_i)
    #logger.debug(average.to_f)
    #act = v.done_rate.present? ? (r_day*(v.done_rate.to_f*0.01)):0
    if v.due_date < Date.today
      now = r_day
    else
      now = Date.today - (v.start_date-1)
    end

    estimated = now*average
    #logger.debug(estimated.to_f)
    #logger.debug(v.act_rate.to_f)
    if  is_closed.find {|n| n.to_i == v.status_id.to_i}
      '#89d6e2' # is_closed
    elsif v.act_rate < estimated
      '#FF727B' # delayed
    else
      '#a5e899' # as scheduled
    end

  end
end
