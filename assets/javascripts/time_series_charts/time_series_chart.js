var TimeSeriesChart = function(arg){

  this.data = arg.data;
  this.keys = arg.keys;
  this.sum = arg.sum;

};

TimeSeriesChart.prototype.set = function(arg){
  this.data = arg.data;
  this.keys = arg.keys;
  this.sum = arg.sum;
};

TimeSeriesChart.prototype.draw = function(){

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
  var margin = {top: 20, right: 20, bottom: 30, left: 50};
  var width = $('#MyGraph').width() - margin.left - margin.right;
  var height = $('#MyGraph').height() - margin.top - margin.bottom;

  var g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var x = d3.scaleTime()
      .domain(d3.extent(this.data, function(d) {return new Date(d.date); }))
      .range([0, width]);

  var y = d3.scaleLinear()
      .domain([0,this.sum])
      .range([height, 0])
      .nice();

  var z = d3.scaleOrdinal(d3.schemeCategory20)
      .domain(this.keys);

  var stack = d3.stack();

  stack.keys(this.keys);

  var layer = g.selectAll(".layer")
      .data(stack(this.data))
      .enter().append("g")
      .attr("class", "layer");

  var area = d3.area()
      .x(function(d, i) {
        return x(new Date(d.data.date)); })
      .y0(function(d) {
        return y(d[0]); })
      .y1(function(d) {
        return y(d[1]); });

  layer.append("path")
      .attr("class", "area")
      .style("fill", function(d) { return z(d.key); })
      .attr("d", area);

  layer.append("text")
      .attr("x", width - 6)
      .attr("y", function(d) {
        return y((d[d.length - 1][0] + d[d.length - 1][1]) / 2);
      })
      .attr("dy", ".35em")
      .style("font", "10px sans-serif")
      .style("text-anchor", "end")
      .text(function(d) {
        return d.key + '(' +String(d[d.length-1]['data'][d.key]) + ')';
      });

  g.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(x).tickFormat(function(d,i){
        return formatDate(d, "MM/DD");
      }).tickSizeInner(-height));

  g.append("g")
      .attr("class", "axis axis--y")
      .call(d3.axisLeft(y).ticks(10).tickSizeInner(-width));
};
