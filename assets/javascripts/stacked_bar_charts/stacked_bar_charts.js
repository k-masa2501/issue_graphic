var StackedBarChart = function(arg){
  this.data = arg.data;
  this.keys = arg.keys;
  this.sum = arg.sum;
};

StackedBarChart.prototype.set = function(arg){
  this.data = arg.data;
  this.keys = arg.keys;
  this.sum = arg.sum;
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
  var margin = {top: 20, right: 130, bottom: 30, left: 40},
      width =  $('#MyGraph').width() - margin.left - margin.right,
      height =  $('#MyGraph').height() - margin.top - margin.bottom,
      g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var x = d3.scaleBand()
      .rangeRound([0, width])
      .paddingInner(0.05)
      .align(0.1);

  var y = d3.scaleLinear()
      .rangeRound([height, 0]);

  var z = d3.scaleOrdinal(d3.schemeCategory10);

    var keys = this.keys;
  
    x.domain(this.data.map(function(d) { return d.date; }));
    y.domain([0, this.sum]).nice();
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
      .attr("x", function(d) { return x(d.data.date); })
      .attr("y", function(d) { return y(d[1]); })
      .attr("height", function(d) { return y(d[0]) - y(d[1]); })
      .attr("width", x.bandwidth());

  fill.append("g")
      .attr("fill", "#000000")
      .selectAll("text")
      .data(function(d) { return d; })
      .enter().append("text")
      .attr("x", function(d) {
        return x(d.data.date)+(x.bandwidth()/2)+5; })
      .attr("y", function(d) { return y(d[1])+5;})
      .attr("dy", ".35em")
      .style("font", "10px sans-serif")
      .style("text-anchor", "end")
      .text(function(d) {
        var num = d[1]-d[0];
        return  num > 0 ? num:'';});


  g.append("g")
      .attr("class", "axis")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(x));

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
