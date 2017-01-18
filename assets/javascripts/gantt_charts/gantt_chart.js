var GanttChart = function(arg){
  this.data = arg.data;
  this.start_date = arg.start_date;
  this.due_date = arg.due_date;
};

GanttChart.prototype.set = function(arg){
  this.data = arg.data;
  this.start_date = arg.start_date;
  this.due_date = arg.due_date;
};

GanttChart.prototype.draw = function(){

  $('#gantchart').empty();
  $('#svg_footer').empty();

  var fmtFunc = d3.timeParse("%Y-%m-%d %H:%M");
  var svg = d3.select('#gantchart');
  var margin = {top: 40, right: 40, bottom: 80, left: 40};
  var svg_height = (this.data.length*30) + margin.top + margin.bottom;

  $('#gantchart').height(String(svg_height)  + 'px');

  var width =  $('#gantchart').width()  - margin.left - margin.right;
  var height = $('#gantchart').height() - margin.top - margin.bottom;

  var time_scale = d3.scaleTime()
      .range([0, width])
      .domain([fmtFunc(this.start_date), fmtFunc(this.due_date)])
      .nice();

  var tickLen = Math.floor((fmtFunc(this.due_date)-fmtFunc(this.start_date))/(1000 * 60 * 60 * 24));

  svg.append("g")
      .attr("class", "axis-tick")
      .attr( "stroke-width" , 1)
      .attr("transform", "translate("+ margin.left +"," + $('#gantchart').height() + ")")
      .call(
          d3.axisBottom(time_scale)
              .tickSizeInner(-$('#gantchart').height())
              .ticks(tickLen)
      );

  var svg_g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var today = new Date();
  today.setDate(today.getDate()+1);
  today = formatDate(today, "YYYY-MM-DD") + " 00:00";

  // 縦軸のスケール関数を生成
  var y_scale = d3.scaleLinear()
      .domain([0, 100])
      .range([height, 0])
      .nice();

  var line1 = d3.line()
      .x(function(d,i){return time_scale(d['date']);})
      .y(function(d,i){return y_scale(d["value"]);});

  var serie = svg_g.selectAll(".serie")
      .data(this.data)
      .enter().append("g")
      .attr("class", "serie");

  serie.selectAll("rect")
      .data(function(d) { return d; })
      .enter().append("rect")
      .attr("class", "rect")
      .attr("x", function(d) { return time_scale(fmtFunc(d.date)); })
      .attr("y", function(d) { return d.pos; })
      .attr("height", 20 )
      .attr("width", function(d) {
        var end = time_scale(d3.timeHour.offset(fmtFunc(d.date), d.data));
        var start = time_scale(d3.timeHour.offset(fmtFunc(d.date), 0));
        return end-start })
      .attr("fill", function(d) {return d.color });

  // g要素にテキスト要素を加えている。
  serie.selectAll("a")
      .data(function(d) { return d; })
      .enter()
      .append("a")
      .attr("xlink:href",function(d) { return d.href; })
      .attr("target",function(d) { return null != d.href ? "_blank":""; })//  "_blank")
      .append("text")
      .attr("class", "text")
      .text(function(d){ return d.text; })
      .attr("x", function(d) { return time_scale(fmtFunc(d.date)); })
      .attr("y", function(d) { return d.pos+12; })
      .attr("font-size", 10);

  serie.select("a").selectAll("text")
      .data(function(d) { return d; })
      .enter()
      .append("text")
      .attr("class", "text")
      .text(function(d){ return d.text; })
      .attr("x", function(d) { return time_scale(fmtFunc(d.date)); })
      .attr("y", function(d) { return d.pos+12; })
      .attr("font-size", 10);

  svg_g.append("path")
      .datum([{date: fmtFunc(today), value: 0},{date: fmtFunc(today), value: 100}])
      .attr("class", "line1")
      .attr("d", line1);

  $('.div_svg_footer').width(String($('#gantchart').width()) + 'px');

  d3.select('#svg_footer')
      .append("g")
      .attr("class", "axis")
      .attr("transform", "translate(" + margin.left + ",0)")
      .attr( "stroke-width" , 2)
      .call(d3.axisBottom(time_scale)
          .tickFormat(function(d,i){
            return formatDate(d,'YYYY/MM/DD');})

      )
      .selectAll("text")
      .attr("transform", "rotate(45)")
      .attr("dy", 10)
      .attr("dx", 10)
      .style("text-anchor", "start");

};
