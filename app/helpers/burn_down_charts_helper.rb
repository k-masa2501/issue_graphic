module BurnDownChartsHelper

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

end
