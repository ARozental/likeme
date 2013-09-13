

function load_event_table()
{
	
	var table=document.getElementById("event_table");
	var events = document.getElementById("event_table").getAttribute("data-events");
	var oauth_token = $('#event_table').data('oauth_token');
	events = jQuery.parseJSON(events);
	$("body").data("current_events", events);
	var iterations = Math.min(9,events.length);
	
	for (var i=0;i<iterations;i++) //ruins the post if iterations > matches
	{ 		
		add_event_row(events);
	}
	//ajax_events(6,matches);
	//alert("here");
	return "bla";
}


function add_event_row(events)
{
	
	var table=document.getElementById("event_table");
	var event_number = table.rows.length;	
	if(true)//event not null
	{
		insert_event(events[event_number],-1)
	}
	//alert("bla4");
}
function insert_event(event,place) //user == matches[user_number], place = -1
{
	
	var table=document.getElementById("event_table");
	var oauth_token = $('#event_table').data('oauth_token');
	
	var row=table.insertRow(place);
	var cell1=row.insertCell(-1);
	var cell2=row.insertCell(-1);
	var cell3=row.insertCell(-1);
	//cell1.innerHTML = "bla";
	cell2.innerHTML = get_event_details(event,oauth_token);
	cell3.innerHTML = "bla";
	cell1.innerHTML = picture_link(event[0].id,120,oauth_token);
	//alert(event[0]);
	//alert(JSON.stringify(event[0]));
}

function get_event_details(event) 
{
	var name = event[0].name;
	var score = event[1];
	var location = event[0].location;
	var start_time = event[0].start_time;
	var end_time = event[0].end_time;
	var HMTL = ""
	HMTL +="<b>" + name + "</b></br>";
	HMTL += "event score: " + score + "</br>";
	if(location) {HMTL += location + "</br>";}
	HMTL += start_time + "</br>";
	HMTL += end_time + "</br>";
	return HMTL
	
}












