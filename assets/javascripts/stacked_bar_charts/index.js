var IndexController = function(arg){

  this.timer = null;
  this.chart = arg.chart;
  this.url = arg.url;
  this.local = arg.local;

  this.chart.draw();

  this._set_event_lisnter();

  $('.input-day').datepicker({
    dateFormat: 'yy/mm/dd',
    showButtonPanel: true
  });

};

IndexController.prototype.destroy = function(){

  this.timer = null;
  this.chart = null;

  $(".filter-change").off();
  $(window).off('resize');

};

IndexController.prototype._set_event_lisnter = function(){

  $(".filter-change, .input-day").change($.proxy(function(e){
    this._change_selectBox(e)
  },this));

  $(".period-change").change($.proxy(function(e){
    this._change_periodType(e)
  },this));

  $(window).resize($.proxy(function(e){
    this._resize_window(e)
  },this));

};

IndexController.prototype._change_selectBox = function(e){

  var option = {type: "get", url: this.url, data: $('.filter-form').serialize(), dataType: "json"};
  var obj = {done: ajax_done, arg: {index: this}};

  ajax_http_request(option, null, null, obj);

  function ajax_done(recv, arg){

    switch (recv.type){
      case 'sum_act_value':
      case 'count_act_value':
      case 'ticket_amount':
      case 'workload':
      case 'per_period_work':
        arg.index.chart = new StackedBarChart(recv.data);
        arg.index.chart.draw();
        break;
      case 'per_period_oc':
        arg.index.chart = new StackedBarOcChart(recv.data);
        arg.index.chart.draw();
        break;
    }
    
    $("#cost_summarys_view").html(recv.render_summary);

  }
  
};

IndexController.prototype._change_periodType = function(e){

  var target = $(e.currentTarget);
  switch (target.val()){
    case 'daily':
      $('#period-input-day').show();
      $('#period-input-week').hide();
      $('#period-input-month').hide();
      break;
    case 'weekly':
      $('#period-input-day').hide();
      $('#period-input-week').show();
      $('#period-input-month').hide();
      break;
    case 'monthly':
      $('#period-input-day').hide();
      $('#period-input-week').hide();
      $('#period-input-month').show();
      break;
  }

};

IndexController.prototype._resize_window = function(e){

  if (this.timer !== false) {
    clearTimeout(this.timer);
  }
  
  this.timer = setTimeout($.proxy(function(){
    this.chart.draw();
  },this), 200);

};
