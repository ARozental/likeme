// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require_tree .
Object.prototype.getName = function() { 
   var funcNameRegex = /function (.{1,})\(/;
   var results = (funcNameRegex).exec((this).constructor.toString());
   return (results && results.length > 1) ? results[1] : "";
};

function insert_user(user,place) //user == matches[user_number], place = -1
{
	var table=document.getElementById("matche_table");
	if(place != -1){place = place*2;} //2 rows for every user
	var row1=table.insertRow(place);
	var cell1=row1.insertCell(-1);
	var cell2=row1.insertCell(-1);
	cell1.innerHTML = picture_link(user[0].id,120);
	cell1.className = 'face_td';
	cell1.rowSpan="2";
	cell1.style.padding="0px";
	//cell2.innerHTML = "<a href=\"http://www.facebook.com/" + matches[user_number][0].id + "\"><img src=\"https://graph.facebook.com/" + matches[user_number][0].id + "/picture?width=120&height=120\" width=" + "120" + " height=" + "120" + "></a>";		
	cell2.rowSpan="2";
	var user_div = document.createElement("div");
	user_div.className = 'text_div';		
	user_div.style.height = "120px";
	user_div.style.maxHeight = "120px";
	user_div.style.overflowY='auto';
	user_div.style.padding="0px";
	var user_text = name_link(user[0]);
	user_text += print_stats(user[0]) +"<br />";
	user_text += user[2] +"% Likeable" +"<br />";
	//alert(JSON.stringify(matches[user_number][0]));
	if (user[0].quotes != null)
	{
		user_text += user[0].quotes;
	}		
	//user_div.innerHTML = name_link(matches[user_number][0]) + print_stats(matches[user_number][0]) +"<br />"+ matches[user_number][2] +"% Likeable" +"<br />"+ matches[user_number][0].quotes;
	user_div.innerHTML = user_text;
	cell2.appendChild(user_div);
	//cell2.innerHTML = name_link(matches[user_number][0]) + print_stats(matches[user_number][0]);
	
	for (var k=0;k<3;k++)
	{ 
		var cell=row1.insertCell(-1);
		cell.className = 'like_td';
		cell.style.padding="0px";
		cell.style.maxHeight="40px";
		try
		{
			cell.innerHTML = picture_link(user[1][k],60);
		}
		catch(err)
		{
		}
	}
	//alert(place);	
	if(place >= 0){place++;}
	//alert(place);
	var row2=table.insertRow(place);
	for (var k=0;k<3;k++)
	{ 
		var cell=row2.insertCell(-1);
		cell.className = 'like_td';
		cell.style.padding="0px";
		cell.style.maxHeight="40px";
		try
		{
			cell.innerHTML = picture_link(user[1][k+3],60);
		}
		catch(err)
		{
		}
	}
}


function add_row(matches)
{
var table=document.getElementById("matche_table");
	var user_number = table.rows.length/2;
	if(matches[user_number][0].id != null)
	{
		insert_user(matches[user_number],-1)
	}
}

function update_table(new_matches,old_matches,recursion)
{
	//var old_matches = document.getElementById("matche_table").getAttribute("data-matches");	
	//old_matches = jQuery.parseJSON(old_matches);
	var old_matches_index = 0;
	var new_matches_index = 0;
	//alert(new_matches[0][0].id);
	//insert_user(new_matches[0],1);
	
	while(new_matches_index<new_matches.length && old_matches_index<old_matches.length)
	{
		if(new_matches[new_matches_index][2]>old_matches[old_matches_index][2])
		{
			//if no dupliction
			old_matches.splice(old_matches_index, 0, new_matches[new_matches_index]);
			insert_user(new_matches[new_matches_index],old_matches_index);
			
			new_matches_index++;
			//alert(JSON.stringify(new_matches[new_matches_index][0].name));
		}
		else
		{
			old_matches_index++;
		}
	}
	
	$("body").data("current_matches", old_matches);
	if(recursion<1){return true;}
	else {return ajax_test(recursion-1,old_matches)}	
}


function ajax_test(recursion,matches)
{
	var min_age = document.getElementById("min_age").value;
	var max_age = document.getElementById("max_age").value;
	var search_by = document.getElementById("search_by").value;
	var gender = document.getElementById("gender").value;
	var relationship_status = document.getElementById("relationship_status").value;
	var social_network = document.getElementById("social_network").value;
	
	//var old_matches = document.getElementById("matche_table").getAttribute("data-matches");// non recursive!
	//old_matches = jQuery.parseJSON(old_matches);
	old_matches = matches;
	var excluded_users = [];
	for(var i=0;i<old_matches.length;i++){excluded_users.push(old_matches[i][0].id);}
	//alert(excluded_users);
	
	var result = $.post("/home/ajax_matching",
	{ excluded_users: excluded_users, min_age: min_age, max_age: max_age, search_by: search_by,gender: gender,relationship_status: relationship_status,social_network: social_network},
	function(response) {
		//alert(recursion);
		//insert_user(response[7],1) //it works :) insert user of rank 7 after place 1
		//add_row(response);
		update_table(response,old_matches,recursion);
		//alert(JSON.stringify(response));
		return "good";
	})
	//.done(function() { alert("second success"); })
	.fail(function() { 
		alert('error');
		return "error"; })
	//.always(function() { alert("finished"); });
	//setTimeout('', 9000);
	//alert(JSON.stringify(result));
	return result;
}

function load_table()
{
	//$("body").data("foo", 52);
	//alert($("body").data("foo"));
	//var h = ajax_test();
	//alert(h);
	var table = document.getElementById("matche_table");
	var matches = document.getElementById("matche_table").getAttribute("data-matches");
	matches = jQuery.parseJSON(matches);
	for (var i=0;i<9;i++)
	{ 
	add_row(matches);
	}
	ajax_test(3,matches);
	//alert("ff");
	//setTimeout(function() {alert($("body").data("current_matches"));}, 3000);
	//matches = document.getElementById("matche_table").getAttribute("data-current_matches_json");
	//alert(JSON.stringify(matches));

}






function picture_link(id,size)
{
    size = size.toString(); //resolution is 120px
    id = id.toString();
    html = "<a href=\"http://www.facebook.com/" + id + "\"><img src=\"https://graph.facebook.com/" + id + "/picture?width=" + size + "&height=" + size + "\" width=" + size + " height=" + size + "></a>"
    return html;
}

function name_link(user)
{
    html = "<a href=\"http://www.facebook.com/" + user.id.toString() + "\">" + user.name + "</a>";
    return html;
}

function print_stats(user)
{
    var relationship_status = "";
    var gender = "";
    var age = "";
    var location = "";
    
    if(user.relationship_status != null){relationship_status = ", " + user.relationship_status;}
    if(user.gender != null){gender = ", " + user.gender;}
    if(user.location != null){location = ", " + user.location.name;}
    if(user.age != null){age = ", " + user.age;}
    
    html = relationship_status + gender + age + location;
    return html;
}


