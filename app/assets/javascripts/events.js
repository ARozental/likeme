

function load_event_table()
{
	
	var table=document.getElementById("event_table");
	var events = document.getElementById("event_table").getAttribute("data-events");
	var oauth_token = $('#event_table').data('oauth_token');
	events = jQuery.parseJSON(events);
	$("body").data("current_events", events);
	var iterations = Math.min(25,events.length);
	
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
	
	//cell1 
	cell1.innerHTML = picture_link(event[0].id,120,oauth_token);
	cell1.className = 'event_pic';
	
	//cell2
	var event_div = document.createElement("div");
	event_div = get_event_details(event); //todo: a callback to update this div from FB if I have a valid token
	cell2.appendChild(event_div);
	cell2.className = 'event_details_td';
	//cell3
	var users_div = document.createElement("div");
	users_div = get_event_users(event,oauth_token); //todo: a callback to update this div from FB if I have a valid token
	
	cell3.appendChild(users_div);
	users_div.className = 'event_users_details';
	cell3.className = 'event_users_details';
	//alert(event[0]);
	//alert(JSON.stringify(event[0]));
}

function get_event_users(event,oauth_token)
{

	users_div = document.createElement("div");
	var iterations = Math.min(9,event[2].length);		
	for (var i=0;i<iterations;i++) 
	{
		user_div = document.createElement("div");
		user_div.style.height = "67px";
		
		var picture = picture_link(JSON.stringify(event[2][i][0].id),60,oauth_token);
		var name = name_link(event[2][i][0]);
		var stats = print_stats(event[2][i][0]);
		
		//user_div.innerHTML = picture_link(JSON.stringify(event[2][i][0].id),60,oauth_token);
		user_div.innerHTML = "<div>" + picture + "</div>"+'<div style="position: relative; left: 65px; top: -63px; width: 160px; overflow-y: auto; height: 60px;">'+ name + stats+ ", " + event[2][i][2] + "% like me" + "</div>"                                
		//user_div.innerHTML =  picture +  name + stats
		users_div.appendChild(user_div);
	}
	//users_div.innerHTML = "vvvv";
	return users_div
}

function get_event_details(event) 
{
	var name = event[0].name;
	var score = event[1];
	var location = event[0].location;
	var time_frame = format_time(event[0].start_time,event[0].end_time);
	var description = event[0].description;
	
	event_div = document.createElement("div");
	event_div.className = 'event_details';
	
		name_div = document.createElement("div");
		name_div.innerHTML = name;
		name_div.className = 'event_name';
		event_div.appendChild(name_div);
		
		/*score_div = document.createElement("div");
		score_div.innerHTML = "event score: " + Math.round(score);
		event_div.appendChild(score_div);*/
		
	if(location){
		location_div = document.createElement("div");
		location_div.innerHTML = location;
		event_div.appendChild(location_div);			
	}
	if(time_frame){
		time_div = document.createElement("div");
		time_div.innerHTML = time_frame;
		event_div.appendChild(time_div);			
	}
	if(description){
		description_div = document.createElement("div");
		description_div.innerHTML = '</br><i><font color="grey">' + description + '</i></font>';
		event_div.appendChild(description_div);			
	}
	return event_div
	
}

function format_time(start_time,end_time)
{
	//var time = start_time.substring(0,10);
	if(start_time == null && end_time == null){return null}
	
	if(end_time == null){
		var start = new Date(start_time);
		start=start.toString().replace(":00 "," ");
		start = start.substring(0, start.indexOf('G')); //cut GTM
		return start
	}
	
	//both start and end time	
	var start = new Date(start_time);
	var end = new Date(end_time);
	if(start.toDateString() == end.toDateString()){ //same date
		start=start.toString().replace(":00 ","");
		start = start.substring(0, start.indexOf('G')); //cut GTM
		end = end.toTimeString();
		end = end.replace(":00 "," ");
		end = end.substring(0, 5);		
		return start + "-" + end
	}
	
	start = start.toString().replace(":00 ","");
	start = start.substring(0, start.indexOf('G')); //cut GTM
	end = end.toString().replace(":00 ","");
	end = end.substring(0, end.indexOf('G')); //cut GTM
	return start + " until </br>" + end
}










