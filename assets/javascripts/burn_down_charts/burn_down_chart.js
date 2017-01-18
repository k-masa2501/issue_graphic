var BurnDownsChart = function(arg){
  
  this.dset1= arg.o_dset1;
  this.dset2= arg.o_dset2;
  this.dset3= arg.o_dset3;

};

BurnDownsChart.prototype.set = function(arg){
  this.dset1= arg.o_dset1;
  this.dset2= arg.o_dset2;
  this.dset3= arg.o_dset3;
};

BurnDownsChart.prototype.draw = function(){

  $('#MyGraph').empty();

  var data_set = this._deep_copy();
  var svg = null;

  if (data_set.dset1 == null && data_set.dset2 == null && data_set.dset3 == null){

    svg = d3.select("#MyGraph")
        .append("g")
        .append("text").attr("dy", 10).attr("y", 10).attr("dx", 10).attr("x", 10)
        .text('There is no data to be drawn.');
    
    return;
  }
  
  var max_d = d3.max(data_set.dset1, function(d){ return d.value; });

  // 時間のフォーマット
  var fmtFunc = d3.timeParse("%Y-%m-%d");
  var today = formatDate(new Date(), "YYYY-MM-DD");

  // Ｘ，Ｙ軸を表示できるようにグラフの周囲にマージンを確保する
  var margin = {top: 40, right: 80, bottom: 80, left: 80};
  var width = $('#MyGraph').width() - margin.left - margin.right;
  var height = $('#MyGraph').height() - margin.top - margin.bottom;

  // SVGの表示領域を生成
  svg = d3.select("#MyGraph")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");

  // 時間軸のスケール関数を生成
  var time_scale = d3.scaleTime()
      .range([0, width]);

  // 縦軸のスケール関数を生成
  var y_scale = d3.scaleLinear()
      .domain([0, max_d])
      .range([height, 0])
      .nice();

  // 折れ線
  var line1 = d3.line()
      .x(function(d,i){return time_scale(d['date']);})
      .y(function(d,i){return y_scale(d["value"]);});

  data_set.dset1.forEach(function(d){
    if (typeof d.date == 'string') d.date = fmtFunc(d.date);
  });

  data_set.dset2.forEach(function(d){
    if (typeof d.date == 'string') d.date = fmtFunc(d.date);
  });

  data_set.dset3.forEach(function(d){
    if (typeof d.date == 'string') d.date = fmtFunc(d.date);
  });

  time_scale
      .domain(d3.extent(data_set.dset1, function(d){ return d.date; }))
      .nice();

  // 予定
  svg.append("path")
      .datum(data_set.dset1)
      .attr("class", "line1")
      .attr("d", line1);

  // 予定実績
  svg.append("path")
      .datum(data_set.dset3)
      .attr("class", "line3")
      .attr("d", line1);

  // 実績
  svg.append("path")
      .datum(data_set.dset2)
      .attr("class", "line2")
      .attr("d", line1);

  // 予定
  svg.selectAll("circle1")
      .data(data_set.dset1)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#ff8d2d'; })
      .attr("cx", function(d){ return time_scale(d['date']); })
      .attr("cy", function(d){ return y_scale(d["value"]); });

  // 予定実績
  svg.selectAll("circle3")
      .data(data_set.dset3)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#989898'; })
      .attr("cx", function(d){return time_scale(d['date']);})
      .attr("cy", function(d){ return y_scale(d["value"]); });

  // 実績
  svg.selectAll("circle2")
      .data(data_set.dset2)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#00d324'; })
      .attr("cx", function(d){ return time_scale(d['date']); })
      .attr("cy", function(d){ return y_scale(d["value"]); });

  svg.append("path")
      .datum([{date: fmtFunc(today), value: 5},{date: fmtFunc(today), value: max_d}])
      .attr("class", "line4")
      .attr("d", line1);

  // Ｘ軸を描画
  svg.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(time_scale)
          .tickFormat(function(d,i){
            return formatDate(d, "MM/DD");
          }).tickSizeInner(-height)
      )
      .selectAll("text")
      .attr("transform", "rotate(45)")
      .attr("dy", 10)
      .attr("dx", 10)
      .style("text-anchor", "start");

  // Ｙ軸を描画
  svg.append("g")
      .attr("class", "axis")
      .call(d3.axisLeft(y_scale).tickSizeInner(-width));

};


BurnDownsChart.prototype._deep_copy = function(){
  return {dset1: this.dset1,dset2: this.dset2,dset3: this.dset3};
};

