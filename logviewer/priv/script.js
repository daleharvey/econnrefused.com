var room  = "web@conference.econnrefused.com";
var start_date = new Date(2008,11,22);

var formatter = function(val,axis) 
{
    var val = ((val/4)< 12) ? (val/4)+'AM' : ((val/4)-12)+'PM';
    return (val == "0PM") ? "12PM" : (val == "0AM") ? "12AM" : val;
};

var graph_options = 
{
    lines: { show: true },
    xaxis: { min:0, max:96, tickFormatter:formatter, tickSize:12},
    yaxis: { min:0, max:100, tickSize:20}
};

$(function()
{
    var pick_date = function(date)
    {
	var d = date.split("/");
	var notstupiddate = d[2]+"/"+d[0]+"/"+d[1];
	var url = room+"/"+notstupiddate;
	$("#current span").text(notstupiddate);
	$.getJSON(url+".freq",load_graph);  
	$("#log").load(url+".html");
    };

    var load_graph = function(data)
    {
        var d1 = [];
	for(var i = 0; i < data.frequency.length; i++)
	{
	    d1.push([i,data.frequency[i].v]);
        } 
	$.plot($("#graph"), [{data:d1}], graph_options);
    };       

    $("#datepicker").datepicker(
    {
        minDate: start_date,
	maxDate: new Date(),
	onSelect: pick_date        
    });

    var now = new Date();
    pick_date((now.getMonth()+1)+"/"+now.getDate()+"/"+now.getFullYear());

});