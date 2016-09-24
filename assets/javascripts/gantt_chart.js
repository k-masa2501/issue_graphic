var GanttCharts = function(gantt_chart){
  
  var timer = false;
  $(window).resize(function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
      $('#gantchart').empty();
      $('#svg_footer').empty();
      gantt_chart.draw();
    }, 200);
  });
  
};