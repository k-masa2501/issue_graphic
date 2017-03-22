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


var ajax_http_request = function(option, fail, always, obj){
  $.ajax(option)
      .done(function(recv, textStatus, jqXHR ) {
        parse_data(recv, obj);
      })
      .fail(function( jqXHR, textStatus, errorThrown ) {
        if (null != fail) fail(jqXHR, textStatus, errorThrown);
      })
      .always(function(data, textStatus, jqXHR ) {
        if (null != always) always(data, textStatus, jqXHR );
      });

  function parse_data(recv, obj){
    $.each(recv,function(i, val){
      switch (val['method']){
        case 'obj_after':
          $(obj['item']).after(val['value']);
          break;
        case 'done':
          obj['done'](val.data, obj.arg);
          break;
      }
    });
  }

};

// change view
$(document).on("change","select.select_view", function(e){
  location.href = $(this).val();
});
