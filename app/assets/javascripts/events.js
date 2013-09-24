

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
	ajax_events(6,events);
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
function insert_event(event,place) 
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


//todo: make this function
function ajax_events(recursion,events)
{
	var name = document.getElementById("name").value;
	var location = document.getElementById("location").value;
	var with_friends = document.getElementById("with_friends").value;
	var participant_name = document.getElementById("participant_name").value;
	var gender = document.getElementById("gender").value;
	var relationship_status = document.getElementById("relationship_status").value;
	
	old_events = events;
	var excluded_events = [];

	for(var i=0;i<old_events.length;i++){excluded_events.push(old_events[i][0].id);}
	
	//user and event both have attributes "name and location", fix set attribute function in both or do something else here
	var result = $.post("/home/ajax_events",
	{ location: location, name: name, with_friends:with_friends, excluded_events: excluded_events, participant_name: participant_name, gender: gender, relationship_status: relationship_status},
	function(response) {
		//alert("good");
		update_event_table(response,old_events,recursion);
		//alert(JSON.stringify(response));
		return "good";
	})
	//.done(function() { alert("second success"); })
	.fail(function() { 
		//alert('error');
		return "error"; })
	//.always(function() { alert("finished"); });
	//setTimeout('', 9000);
	//alert(JSON.stringify(result));
	return result;
}

//todo here:
function update_event_table(new_events,old_events,recursion)
{
	//new_events = jQuery.parseJSON(new_events);
	var old_events_index = 0;
	var new_events_index = 0;
	//alert(new_events[0][0].id);
	//alert(new_events[0][1]);
	//alert(old_events[0][1]);
	while(new_events_index<new_events.length && old_events_index<old_events.length)
	{
		if(new_events[new_events_index][1]>old_events[old_events_index][1])
		{
			//alert(new_events_index);
			//if no dupliction
			old_events.splice(old_events_index, 0, new_events[new_events_index]);
			insert_event(new_events[new_events_index],old_events_index);
			new_events_index++;
			//alert(JSON.stringify(new_events[new_events_index][0].name));
		}
		else
		{
			//alert("bla");
			old_events_index++;
		}
	}
	
	$("body").data("current_events", old_events);
	if(recursion<1){return true;}
	else {return ajax_events(recursion-1,old_events)}	
}

function postEventsToFeed() {
  	var current_matches = $("body").data("current_events");
  	//alert(current_events[0]);
  	var list = {};
  	for(var i=0;i<3;i++)
  	{
  		var key = (i+1).toString();
  		key = key + ")";
  		var event_link = {};
  		event_link["text"] = current_matches[i][0].name;
  		event_link["href"] = "http://www.facebook.com/" + current_matches[i][0].id;
  		list[key] = event_link;
  	}
  	//alert(JSON.stringify(list));
  	//alert($("body").data("current_matches"));
	//var list = { "1) ":{text: "jenia 90% likeable :))", href:'http://www.facebook.com/100001439566738'} , "lastName":"Doe" }
	//list["2)"] = "ffffs"
    // calling the API ...
    var obj = {
      method: 'feed',
      redirect_uri: 'http://like-me.info/',
      link: 'http://www.like-me.info/',
      picture: 'http://oi44.tinypic.com/1py0c3.jpg',
      name: 'Like me',
      caption: 'events recommended for me:',
      //description: "some useless words",
      properties: list,
      action_links: [{ text: 'action link test', href: 'http://example.com'}]
    };

    function callback(response) { //maybe do it ['post_id'] exist...
    if (response['post_id']) {document.getElementById('notice').innerHTML = "successfully posted to feed"}
      //document.getElementById('msg').innerHTML = "successfully posted to feed";
      //document.getElementById('msg').innerHTML = "Post ID: " + response['post_id'];
    }

    FB.ui(obj, callback);
}



