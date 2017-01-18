$(function(){

  (function(obj){

    if (obj == null) return;

    var input = $("<input type='number' min='0' max='100'>");

    input.attr("id", $(obj).attr("id"));
    input.attr("name", $(obj).attr("name"));
    input.val($p.done_ratio);
    $(obj).after(input);
    $(obj).remove();

  })(document.getElementById("issue_done_ratio"));

});