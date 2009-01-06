function make_url(input)
{
    return input
    .replace(/(ftp|http|https|file):\/\/[\S]+(\b|$)/gim,
'<a href="$&" class="my_link" target="_blank">$&</a>')
    .replace(/([^\/])(www[\S]+(\b|$))/gim,
'$1<a href="http://$2" class="my_link" target="_blank">$2</a>');
}

$(function()
{
  var fun = function(data)
  {
    $.each(data,function()
    {
      $("#twitter").append(
        "<h3>"+prettyDate(this.created_at)+"</h3>"+
        "<div>"+make_url(this.text)+"</div>");
    });
  };

  var url = "http://twitter.com/statuses/user_timeline/"
    +"econnrefused"
    +".json?count=5&callback=?";

  $.getJSON(url,fun);

});