module MyUtility

  def get_project_menber(pjid, params)

    result = Array.new
    member = Member.joins(:user)
                 .where(project_id: pjid)
                 .pluck("concat(users.lastname,' ',users.firstname) as name, users.id")
                 .push([nil, nil])

    if params[:f_assigned_to].present? and 0 < params[:f_assigned_to].length
      member.each do |val2|
        ret = params[:f_assigned_to].find { |val1| val1.to_i == val2[1].to_i }
        result.push(val2) if ret.present?
      end
    end

    return 0 < result.length ? result:member

  end

  def set_filter(params, project_id)

    # 初期値
    params['f_version'] ||= Version
                                .where("project_id = ? and status = 'open'", project_id)
                                .limit(1).pluck('id').first

    filter = [['project_id = ?',project_id]]

    params.each do |key,value|
      case key
        when 'f_assigned_to' then
          filter.push(["assigned_to_id in (?)", value]) if value.present?
        when 'f_tracker' then
          filter.push(["tracker_id in (?)", value]) if value.present?
        when 'f_priority' then
          filter.push(["priority_id in (?)", value]) if value.present?
        when 'f_category' then
          filter.push(["category_id in (?)", value]) if value.present?
        when 'f_status' then
          filter.push(["status_id in (?)", value]) if value.present?
        when 'c_status' then
          filter.push(["status_id in (select id from issue_statuses where is_closed = 0)"])
        when 'today' then
          filter.push(["today in (?)", value]) if value.present?
        when 'f_version' then
          filter.push(["fixed_version_id in (?)", value]) if value.present?
        else
      end
    end

    return filter

  end

end