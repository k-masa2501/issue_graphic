var IndexController = function(arg){

  this.timer = null;
  this.burndown = arg.burndown;
  this.url = arg.url;
  this.url2 = arg.url2;

  this.burndown.draw();

  this._set_event_lisnter();

};

IndexController.prototype.destroy = function(){

  this.timer = null;
  this.burndown = null;
  this.url = null;

  $(".filter-change").off();
  $(document).off('click', '.pulldown');
  $(window).off('resize');

};

IndexController.prototype._set_event_lisnter = function(){

  $(".filter-change").change($.proxy(function(e){
    this._change_selectBox(e)
  },this));

  $(document).on('click', '.pulldown', $.proxy(function(e){
  //$(".pulldown").click($.proxy(function(e){
    this._click_act_tableTr(e)
  },this));

  $(window).resize($.proxy(function(e){
    this._resize_window(e)
  },this));

};

IndexController.prototype._change_selectBox = function(e){

  var option = {type: "get", url: this.url2, data: $('.filter-form').serialize(), dataType: "json"};
  var obj = {done: ajax_done, arg: {burndown: this.burndown}};

  ajax_http_request(option, null, null, obj);
  
  function ajax_done(recv, arg){

    arg.burndown.set({
      o_dset1: recv.estimated,
      o_dset2: recv.atual,
      o_dset3: recv.plan
    });

    arg.burndown.draw();
    
    $("#daily_act_view").html(recv.render_table);
    $("#cost_summarys_view").html(recv.render_summary);

  }
  
};

IndexController.prototype._click_act_tableTr = function(e){

  var tr = $(e.currentTarget);
  var data = null;
  var option = null;
  var obj = null;

  if ($(tr).attr('data-process') == '0') {

    $(tr).attr('data-process', '1');

    data = $('.filter-form').serialize();
    data += '&' + 'today=' + $(tr).children().eq(0).attr('data-date');
    data += '&' + 'cells=' + $(tr).children().length;

    option = {type: "get", url: this.url, data: data, dataType: "json"};
    obj = {item: tr};

    ajax_http_request(option, null, ajax_allways, obj);

  } else {
    $(tr).attr('data-process', '0');
    $(tr).next().remove();
  }

  function ajax_allways(data, textStatus, jqXHR) {
    $(tr).attr('data-process', '1');
  }
};

IndexController.prototype._resize_window = function(e){

  if (this.timer !== false) {
    clearTimeout(this.timer);
  }
  
  this.timer = setTimeout($.proxy(function(){
    $('#MyGraph').empty();
    this.burndown.draw();
  },this), 200);

};
