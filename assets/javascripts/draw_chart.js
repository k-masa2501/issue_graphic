function draw_d3_line_graph(o_dset1, o_dset2, o_dset3){

  if (o_dset1 === null && o_dset2 === null && o_dset3 === null){
    $('#MyGraph').html("<text dy='10' y='10' x='10' dx='10'>There is no data to be drawn.</text>");
    return;
  }

  var dset1 = jQuery.extend(true, [], o_dset1);
  var dset2 = jQuery.extend(true, [], o_dset2);
  var dset3 = jQuery.extend(true, [], o_dset3);

  var interal = 0;

  if (dset1.length < 31){
    interal = 1;
  }else if (31 <= dset1.length && dset1.length < 120){
    interal = 5;
  }else if (120 <= dset1.length && dset1.length < 240){
    interal = 10;
  }else if (240 <= dset1.length && dset1.length < 365){
    interal = 15;
  }else{
    interal = 30;
  }

  var max_d = d3.max(dset1, function(d){ return d.value; });

  // 時間のフォーマット
  var fmtFunc = d3.time.format("%Y-%m-%d");
  var today = formatDate(new Date(), "YYYY-MM-DD");

  // Ｘ，Ｙ軸を表示できるようにグラフの周囲にマージンを確保する
  var margin = {top: 40, right: 80, bottom: 80, left: 80};
  var width = $('#MyGraph').width() - margin.left - margin.right;
  var height = $('#MyGraph').height() - margin.top - margin.bottom;

  // SVGの表示領域を生成
  var svg = d3.select("#MyGraph")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");

  // 時間軸のスケール関数を生成
  var time_scale = d3.time.scale()
      .range([0, width]);
  // 縦軸のスケール関数を生成
  var y_scale = d3.scale.linear()
      .domain([0, max_d])
      .range([height, 0]);

  dset1.forEach(function(d){
    d.date = fmtFunc.parse(d.date);
  });

  dset2.forEach(function(d){
    d.date = fmtFunc.parse(d.date);
  });

  dset3.forEach(function(d){
    d.date = fmtFunc.parse(d.date);
  });

  time_scale.domain(d3.extent(dset1, function(d){ return d.date; }));

  // 折れ線
  var line1 = d3.svg.line()
      .x(function(d,i){return time_scale(d['date']);})
      .y(function(d,i){return y_scale(d["value"]);});

  // 予定
  svg.append("path")
      .datum(dset1)
      .attr("class", "line1")
      .attr("d", line1);

  // 予定実績
  svg.append("path")
      .datum(dset3)
      .attr("class", "line3")
      .attr("d", line1);

  // 実績
  svg.append("path")
      .datum(dset2)
      .attr("class", "line2")
      .attr("d", line1);

  // 予定
  svg.selectAll("circle1")
      .data(dset1)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#ff8d2d'; })
      .attr("cx", function(d){ return time_scale(new Date(d['date'])); })
      .attr("cy", function(d){ return y_scale(d["value"]); });

  // 予定実績
  svg.selectAll("circle3")
      .data(dset3)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#989898'; })
      .attr("cx", function(d){
        return time_scale(new Date(d['date']));
      })
      .attr("cy", function(d){ return y_scale(d["value"]); });

  // 実績
  svg.selectAll("circle2")
      .data(dset2)
      .enter()
      .append("circle")
      .attr("r",6)
      .attr("fill", function(d){ return '#00d324'; })
      .attr("cx", function(d){ return time_scale(new Date(d['date'])); })
      .attr("cy", function(d){ return y_scale(d["value"]); });

  svg.append("path")
      .datum([{date: fmtFunc.parse(today), value: 5},{date: fmtFunc.parse(today), value: max_d}])
      .attr("class", "line4")
      .attr("d", line1);

  // Ｘ軸を描画
  svg.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.svg.axis()
          .scale(time_scale)
          .innerTickSize(-height)
          .outerTickSize(0)
          .orient("bottom")
          .ticks(d3.time.day, interal)
          .tickFormat(function(d,i){
            return fmtFunc(d);
          })
      )
      .selectAll("text")
      .attr("transform", "rotate(45)")
      .attr("dy", 10)
      .attr("dx", 10)
      .style("text-anchor", "start");

  // Ｙ軸を描画
  svg.append("g")
      .attr("class", "axis")
      .call(d3.svg.axis()
          .scale(y_scale)
          .orient("left")
          .innerTickSize(-width)
          .outerTickSize(0)
      );
}

/**
 * 日付をフォーマットする
 * @param  {Date}   date     日付
 * @param  {String} [format] フォーマット
 * @return {String}          フォーマット済み日付
 *  出展：http://qiita.com/osakanafish/items/c64fe8a34e7221e811d0
 */
var formatDate = function (date, format) {
  if (!format) format = 'YYYY-MM-DD hh:mm:ss.SSS';
  format = format.replace(/YYYY/g, date.getFullYear());
  format = format.replace(/MM/g, ('0' + (date.getMonth() + 1)).slice(-2));
  format = format.replace(/DD/g, ('0' + date.getDate()).slice(-2));
  format = format.replace(/hh/g, ('0' + date.getHours()).slice(-2));
  format = format.replace(/mm/g, ('0' + date.getMinutes()).slice(-2));
  format = format.replace(/ss/g, ('0' + date.getSeconds()).slice(-2));
  if (format.match(/S/g)) {
    var milliSeconds = ('00' + date.getMilliseconds()).slice(-3);
    var length = format.match(/S/g).length;
    for (var i = 0; i < length; i++) format = format.replace(/S/, milliSeconds.substring(i, i + 1));
  }
  return format;
};

$(function(){
  var timer = false;
  $(window).resize(function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
      $('#MyGraph').empty();
      draw_d3_line_graph(g_dSet1,g_dSet2,g_dSet3);
    }, 200);
  });
});

