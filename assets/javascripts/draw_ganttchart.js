var DrawGanttCharts = function(o_data, o_start_date, o_due_date){

  this.draw = function(){

    var data_set =  deep_copy();
    var fmtFunc = d3.time.format("%Y-%m-%d %H:%M");
    var svg = d3.select('#gantchart');
    var margin = {top: 40, right: 80, bottom: 80, left: 80};
    var svg_height = (data_set.data.length*30) + margin.top + margin.bottom;

    $('#gantchart').height(String(svg_height < 450 ? 450: svg_height)  + 'px');

    var width =  $('#gantchart').width()  - margin.left - margin.right;
    var height = $('#gantchart').height() - margin.top - margin.bottom;

    var time_scale = d3.time.scale()
        .range([0, width])
        .domain([fmtFunc.parse(data_set.start_date), fmtFunc.parse(data_set.due_date)])
        .nice();

    var svg_g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var today = formatDate(new Date(), "YYYY-MM-DD") + " 00:00";

    var serie = svg_g.selectAll(".serie")
        .data(data_set.data)
        .enter().append("g")
        .attr("class", "serie");

    serie.selectAll("rect")
        .data(function(d) { return d; })
        .enter().append("rect")
        .attr("class", "rect")
        .attr("x", function(d) { return time_scale(fmtFunc.parse(d.date)); })
        .attr("y", function(d) { return d.pos; })
        .attr("height", 20 )
        .attr("width", function(d) {
          var next = time_scale(d3.time.hour.offset(fmtFunc.parse(d.date), d.data));
          var d = time_scale(d3.time.hour.offset(fmtFunc.parse(d.date), 0));
          return next-d })
        .attr("fill", function(d) {return d.color });

    // g要素にテキスト要素を加えている。
    serie.selectAll("text")
        .data(function(d) { return d; })
        .enter().append("text")
        .attr("class", "text")
        .text(function(d){ return d.text; })
        .attr("x", function(d) { return time_scale(fmtFunc.parse(d.date)); })
        .attr("y", function(d) { return d.pos+12; })
        .attr("font-size", 10);
    
    // 縦軸のスケール関数を生成
    var y_scale = d3.scale.linear()
        .domain([0, 100])
        .range([height, 0])
        .nice();

    var line1 = d3.svg.line()
        .x(function(d,i){return time_scale(d['date']);})
        .y(function(d,i){return y_scale(d["value"]);});

    svg_g.append("path")
        .datum([{date: fmtFunc.parse(today), value: 0},{date: fmtFunc.parse(today), value: 100}])
        .attr("class", "line1")
        .attr("d", line1);

    $('.div_svg_footer').width(String($('#gantchart').width()) + 'px');

    d3.select('#svg_footer').append("g")
        .attr("class", "axis")
        .attr("transform", "translate(" + margin.left + ",0)")
        .attr( "stroke-width" , 2)
        .call(d3.svg.axis()
            .scale(time_scale)
            .innerTickSize(10)
            .outerTickSize(0)
            .orient("bottom")
            .tickFormat(function(d,i){return d3.time.format("%m-%d")(d);})
        )
        .selectAll("text")
        .attr("transform", "rotate(45)")
        .attr("dy", 10)
        .attr("dx", 10)
        .style("text-anchor", "start");
  };

  function deep_copy(){
    return {
      data: jQuery.extend(true, [], o_data),
      start_date: String(o_start_date),
      due_date: String(o_due_date)};
  }

};
