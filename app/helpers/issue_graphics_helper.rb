module IssueGraphicsHelper

  def custom_options_for_select(array, default=nil)
    array.unshift([I18n.t('issue_graphics.unselected'),nil])
    options_for_select(array, default)
  end

  def get_num_color(n)
    color = ""
    if 0 <= n
      color = 'surplus'
    else
      color = 'deficit'
    end
  end

  def get_n_color_of_assignend(n)
    color = ""
    if 0 < n
      color = 'surplus'
    else
      color = 'deficit'
    end
  end

  def uname_opacity(v,flg)
    if 1 == flg
      "<span style='opacity: 0'>" + ERB::Util.html_escape(v) + '</span>'
    else
      "<span>" + ERB::Util.html_escape(v) + '</span>'
    end
  end

  def gantt_color(v, is_closed)

    r_day = v.due_date - (v.start_date-1)
    act = v.done_ratio.present? ? (r_day*v.done_ratio):0
    now = Date.today - (v.start_date-1)

    if  /(^|,)#{v.status_id}(,|$)/.match(is_closed.join(','))
      '#3CEBFF' # is_closed
    elsif act < now
      '#FF727B' # delayed
    else
      '#6DFFB6' # as scheduled
    end

  end

end
