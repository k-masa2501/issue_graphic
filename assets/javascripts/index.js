var Indexes = function(ajax_url, line_graph){

  $(".filter-change").change( function() {
    location.href = location.href.replace(/\?.*$/,"") + '?' + $('.filter-form').serialize( );
  });

  $(".pulldown").click(function(){

    var tr = this;

    $(tr).removeClass("pulldown");

    if ($(tr).attr('data-process') == '0'){

      $(tr).attr('data-process', '1');

      var data = $('.filter-form').serialize( ) ;
      data += '&' + 'today=' + $(this).children().eq(0).attr('data-date');
      data += '&' + 'cells=' + $(this).children().length;

      $.ajax({
        type: "get",
        url: ajax_url,
        data: data,
        dataType: "json"
      }).done(function(  data, textStatus, jqXHR ) {
        $(tr).after(data['html']);
      }).fail(function( jqXHR, textStatus, errorThrown ) {
        $(tr).attr('data-process', '0');
      });

    }else{
      $(tr).attr('data-process', '0');
      $(tr).next().remove();
    }

    $(tr).addClass("pulldown");

  });

  var timer = false;
  $(window).resize(function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
      $('#MyGraph').empty();
      line_graph.draw();
    }, 200);
  });

};