var StackedBarChart = function(arg){
  if (null != arg){
    this.set(arg);
  }
};

StackedBarChart.prototype.set = function(arg){
  this.data = arg.data;
  this.keys = arg.keys;
};

StackedBarChart.prototype.draw = function(){

  $('#MyGraph').empty();

  var svg = null;

  if (0 >= this.data.length){

    svg = d3.select("#MyGraph")
        .append("g")
        .append("text").attr("dy", 10).attr("y", 10).attr("dx", 10).attr("x", 10)
        .text('There is no data to be drawn.');

    return;
  }

  svg = d3.select("#MyGraph");
  var margin = {top: 20, right: 130, bottom: 90, left: 40},
      width =  $('#MyGraph').width() - margin.left - margin.right,
      height =  $('#MyGraph').height() - margin.top - margin.bottom,
      g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  
  var x = d3.scaleBand()
      .rangeRound([0, width])
      .paddingInner(0.05)
      .align(0.1);

  var y = d3.scaleLinear()
      .rangeRound([height, 0]);

  var z = d3.scaleOrdinal(d3.schemeCategory20);

  var keys = this.keys;

  x.domain(this.data.map(function(d) { return d.date; }));
  y.domain([0, d3.max(this.data, function(d){
    var cnt = 0;
    for(var i=0,len=keys.length;i<len;i++)
    {if (null != d[keys[i]]) cnt += d[keys[i]];}
    return cnt;
  })]).nice();
  z.domain(keys);

  var fill = g.append("g")
      .selectAll("g")
      .data(d3.stack().keys(keys)(this.data))
      .enter().append("g")
      .attr("fill", function(d) { return z(d.key); })
      .attr("class", 'dataSet' )
      .attr("data-key", function(d) { return d.key; });

  fill.selectAll("rect")
      .data(function(d) { return d; })
      .enter().append("rect")
      .attr("x", function(d) { return x(d.data.date)+10; })
      .attr("y", function(d) { return y(d[1]); })
      .attr("height", function(d) {
        return (function(val){return 0 < val ? val:0})(y(d[0]) - y(d[1]))})
      .attr("width", x.bandwidth());

  fill.append("g")
      .attr("fill", "#000000")
      .selectAll("text")
      .data(function(d) { return d; })
      .enter().append("text")
      .attr("x", function(d) {
        return x(d.data.date)+(x.bandwidth()/2)+15; })
      .attr("y", function(d) { return y(d[1])+5;})
      .attr("dy", ".35em")
      .style("font", "10px sans-serif")
      .style("text-anchor", "end")
      .text(function(d) {
        var num = d[1]-d[0];
        return  num > 0 ? num:'';});


  g.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(10," + height + ")")
      .call(d3.axisBottom(x))
      .selectAll("text")
      .attr("transform", "rotate(45)")
      .attr("dy", 10)
      .attr("dx", 10)
      .style("text-anchor", "start");

  g.append("g")
      .attr("class", "axis")
      .call(d3.axisLeft(y).ticks(null, "s").tickSizeInner(-width))
      .append("text")
      .attr("x", 2)
      .attr("y", y(y.ticks().pop()) + 0.5)
      .attr("dy", "0.32em")
      .attr("fill", "#000")
      .attr("font-weight", "bold")
      .attr("text-anchor", "start");

  var legend = g.append("g")
      .attr("font-family", "sans-serif")
      .attr("font-size", 10)
      .attr("text-anchor", "end")
      .selectAll("g")
      .data(keys.slice().reverse())
      .enter().append("g")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });

  legend.append("rect")
      .attr("x", width+margin.right- 25)// )
      .attr("width", 19)
      .attr("height", 19)
      .attr("fill", z);

  legend.append("text")
      .attr("x", width+margin.right- 30)// )
      .attr("y", 9.5)
      .attr("dy", "0.32em")
      .text(function(d) { return d; });

};

var StackedBarOcChart = function(arg){
  if (null != arg){
    this.set(arg);
  }
};

StackedBarOcChart.prototype.set = function(arg){

  this.data = new Array();
  this.k_oc = new Array();
  this.oc_desc = new Array();
  this.diff = null;
  this.keys = null;

  for(var key in arg.d){
    this.data.push(arg.d[key].data);
  }

  for(var key in arg.k1){
    this.k_oc.push(key);
    this.oc_desc.push(arg.k1[key]);
  }

  this.keys = arg.k2;
  this.diff = arg.diff;
  console.log(this.diff);

};

StackedBarOcChart.prototype.draw = function(){

  $('#MyGraph').empty();

  var svg = null;

  for (var i=0,len=this.data.length; i < len; i++){
    if (0 >= this.data[i].length){
      svg = d3.select("#MyGraph")
          .append("g")
          .append("text").attr("dy", 10).attr("y", 10).attr("dx", 10).attr("x", 10)
          .text('There is no data to be drawn.');
      return;
    }
  }

  svg = d3.select("#MyGraph");
  var margin = {top: 20, right: 130, bottom: 90, left: 40},
      width =  $('#MyGraph').width() - margin.left - margin.right,
      height =  $('#MyGraph').height() - margin.top - margin.bottom,
      g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var x = d3.scaleBand()
      .rangeRound([0, width])
      .paddingInner(0.05)
      .align(0.1);

  var x2 = d3.scaleBand()
      .rangeRound([0, width])
      .paddingInner(0.05)
      .align(0.1);

  var y = d3.scaleLinear()
      .rangeRound([height, 0]);

  var z = d3.scaleOrdinal(d3.schemeCategory20);

  var keys = this.keys;

  x.domain(this.data[0].map(function(d) { return d.date; }));

  x2.domain((function(oc, len){
    for (var i1=0,len1=len,tmp = new Array(); i1 < len1; i1++){
      for (var i2=0,len2=oc.length; i2 < len2; i2++)
      {tmp.push(String(i1+1)+'.'+oc[i2])}
    }
    return tmp;
  }(this.k_oc, this.data[0].length)));

  var max = d3.max(this.diff, function(d){return d.value});

  y.domain([0, d3.max(this.data, function(d){
    for(var i1=0,len1=d.length; i1 < len1; i1++){
      for(var i=0,len=keys.length,cnt=0;i<len;i++)
      {if (null != d[i1][keys[i]]) cnt += d[i1][keys[i]];}
      if (max < cnt) max = cnt;
    }
    return max;
  })]).nice();

  z.domain(keys);
  
  var fill = null;

  for(var index=0,len=this.data.length; index < len; index++){

    fill = g.append("g")
        .selectAll("g")
        .data(d3.stack().keys(keys)(this.data[index]))
        .enter().append("g")
        .attr("fill", function(d) { return z(d.key); })
        .attr("class", 'dataSet' )
        .attr("data-count", function(d,i) { return i; });

    fill.selectAll("rect")
        .data(function(d) { return d; })
        .enter().append("rect")
        .attr("x", function(d) { return x(d.data.date)+15 + (index*((x.bandwidth()/2)-5)); })
        .attr("y", function(d) { return y(d[1]); })
        .attr("height", function(d) {
          return (function(val){return 0 < val ? val:0})(y(d[0]) - y(d[1]))})
        .attr("width", ((x.bandwidth()/2)-5))
        .attr("class", 'rect1');

    fill.append("g")
        .attr("fill", "#000000")
        .selectAll("text")
        .data(function(d) { return d; })
        .enter().append("text")
        .attr("x", function(d) {
          return x(d.data.date)+(x.bandwidth()/4)+15 + (index*((x.bandwidth()/2)-5)); })
        .attr("y", function(d) { return y(d[1])+5;})
        .attr("dy", ".35em")
        .style("font", "10px sans-serif")
        .style("text-anchor", "end")
        .text(function(d) {
          var num = d[1]-d[0];
          return  num > 0 ? num:'';});
  }

  for(var index=0,len=this.data.length; index < len; index++){
    g.append("g")
        .selectAll("g")
        .data([d3.stack().keys(keys)(this.data[index])[0]])
        .enter().append("g")
        .selectAll("text")
        .data(function(d) { return d; })
        .enter().append("text")
        .attr("x", function(d) {
          return x(d.data.date)+(x.bandwidth()/4)+15 + (index*((x.bandwidth()/2)-5)); })
        .attr("y", function(d) { return (height+10);})
        .attr("dx",   -2)
        .style("font", "8px sans-serif")
        .style("text-anchor", "middle")
        .text($.proxy(function(d, i){
          return this.k_oc[index];},this));
  }

  g.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(10," + height + ")")
      .call(d3.axisBottom(x).ticks(1))
      .selectAll("text")
      .attr("transform", "rotate(45)")
      .attr("dy", 10)
      .attr("dx", 10)
      .style("text-anchor", "start");

  g.append("g")
      .attr("class", "axis")
      .call(d3.axisLeft(y).ticks(null, "s").tickSizeInner(-width))
      .append("text")
      .attr("x", 2)
      .attr("y", y(y.ticks().pop()) + 0.5)
      .attr("dy", "0.32em")
      .attr("fill", "#000")
      .attr("font-weight", "bold")
      .attr("text-anchor", "start");

  // 折れ線
  var line1 = d3.line()
      .x(function(d,i){return x(d.date)+(x.bandwidth()/2);})
      .y(function(d,i){return y(d.value);});

  g.append("path")
      .attr("transform", "translate(10,0)")
      .datum(this.diff)
      .attr("class", "line1")
      .attr("d", line1);

  g.selectAll("circle1")
      .data(this.diff)
      .enter()
      .append("circle")
      .attr("class", "circle1")
      .attr("transform", "translate(10,0)")
      .attr("r",3)
      .attr("cx", function(d){ return x(d.date)+(x.bandwidth()/2); })
      .attr("cy", function(d){ return y(d.value); });

  var path_legend = g.append("g");

  path_legend.append("circle")
      .attr("class", "circle1")
      .attr("transform", "translate("+ (width+margin.right - 15) + ", 45)")
      .attr("r",4);

  path_legend.append("text")
      .attr("transform", "translate("+ (width+margin.right - 100) + ", 45)")
      .attr("dy", "0.32em")
      .text('チケット残件数');

  g.append("g")
      .attr("font-family", "sans-serif")
      .attr("font-size", 10)
      .attr("text-anchor", "end")
      .selectAll("text")
      .data(this.oc_desc)
      .enter().append("text")
      .attr("transform", function(d, i)
      { return "translate("+ (width+margin.right- 10) + "," + (10 + (i * 20)) + ")"; })
      .text(function(d) { return d; });

  var legend = g.append("g")
      .attr("font-family", "sans-serif")
      .attr("font-size", 10)
      .attr("text-anchor", "end")
      .selectAll("g")
      .data(keys.slice().reverse())
      .enter().append("g")
      .attr("transform", function(d, i) { return "translate(0," + (60 + (i * 20)) + ")"; });

  legend.append("rect")
      .attr("x", width+margin.right- 25)
      .attr("width", 19)
      .attr("height", 19)
      .attr("fill", z);

  legend.append("text")
      .attr("x", width+margin.right- 30)
      .attr("y", 9.5)
      .attr("dy", "0.32em")
      .text(function(d) { return d; });
  
};