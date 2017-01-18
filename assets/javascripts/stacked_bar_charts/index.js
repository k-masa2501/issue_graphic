var IndexController = function(arg){

  this.timer = null;
  this.chart = arg.chart;
  this.url = arg.url;

  this.chart.draw();

  this._set_event_lisnter();

};

IndexController.prototype.destroy = function(){

  this.timer = null;
  this.chart = null;

  $(".filter-change").off();
  $(window).off('resize');

};

IndexController.prototype._set_event_lisnter = function(){

  $(".filter-change").change($.proxy(function(e){
    this._change_selectBox(e)
  },this));

  $(window).resize($.proxy(function(e){
    this._resize_window(e)
  },this));

};

IndexController.prototype._change_selectBox = function(e){

  var option = {type: "get", url: this.url, data: $('.filter-form').serialize(), dataType: "json"};
  var obj = {done: ajax_done, arg: {chart: this.chart}};

  ajax_http_request(option, null, null, obj);

  function ajax_done(recv, arg){

    arg.chart.set(recv.data);
    arg.chart.draw();

    $("#cost_summarys_view").html(recv.render_summary);

  }
  
};

IndexController.prototype._resize_window = function(e){

  if (this.timer !== false) {
    clearTimeout(this.timer);
  }
  
  this.timer = setTimeout($.proxy(function(){
    $('#MyGraph').empty();
    this.chart.draw();
  },this), 200);

};
