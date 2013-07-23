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

String.prototype.trunc = 
      function(n){
          return this.substr(0,n-1)+(this.length>n?'&hellip;':'');
      };
Object.prototype.getName = function() { 
   var funcNameRegex = /function (.{1,})\(/;
   var results = (funcNameRegex).exec((this).constructor.toString());
   return (results && results.length > 1) ? results[1] : "";
};
String.prototype.hashCode = function(){
    var hash = 0, i, char;
    if (this.length == 0) return hash;
    for (i = 0, l = this.length; i < l; i++) {
        char  = this.charCodeAt(i);
        hash  = ((hash<<5)-hash)+char;
        hash |= 0; // Convert to 32bit integer
    }
    return hash;
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
	//user_div.style.width = "300px";
	//user_div.style.maxWidth = "300px";
	var user_text = name_link(user[0]);
	user_text += print_stats(user[0]) +"<br />";
	user_text += user[2] +"% Like me" +"<br />";
	//alert(JSON.stringify(matches[user_number][0]));
	if (user[0].quotes != null)
	{
		user_text += "<i><font color='grey'>" + user[0].quotes + "</font><i>";
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
		//alert('error'); it will fail if user presses the button fast and refresh before finish
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
	$("body").data("current_matches", matches);
	for (var i=0;i<9;i++)
	{ 
	add_row(matches);
	}
	ajax_test(2,matches);
	//setTimeout(ajax_test(5,matches), 3000); 
	setTimeout(function(){ajax_test(0,matches)},3000); //do it better, know when logging in for the first time
	setTimeout(function(){ajax_test(0,matches)},6000);
	setTimeout(function(){ajax_test(0,matches)},9000);
	setTimeout(function(){ajax_test(0,matches)},12000);
	//alert("ff");
	//setTimeout(function() {alert($("body").data("current_matches"));}, 3000);
	//matches = document.getElementById("matche_table").getAttribute("data-current_matches_json");
	//alert(JSON.stringify(matches));

}


function add_page_row(pages)
{
var table=document.getElementById("page_table");
	var page_number = table.rows.length/2;
	if(pages[page_number][0] != null)
	{
		insert_page(pages[page_number],-1)
	}
}

function insert_page(page,place) //user == matches[user_number], place = -1
{
	var table=document.getElementById("page_table");
	if(place != -1){place = place*2;} //2 rows for every user
	var row1=table.insertRow(place);
	var cell1=row1.insertCell(-1);
	var cell2=row1.insertCell(-1);
	cell1.innerHTML = picture_link(page[0],120);
	cell1.className = 'face_td';
	cell1.rowSpan="2";
	cell1.style.padding="0px";
	//cell2.innerHTML = "<a href=\"http://www.facebook.com/" + matches[user_number][0].id + "\"><img src=\"https://graph.facebook.com/" + matches[user_number][0].id + "/picture?width=120&height=120\" width=" + "120" + " height=" + "120" + "></a>";		
	cell2.rowSpan="2";
	cell2.innerHTML = '<span style="font-size: 16px;" id="'+ "l" + page[0] +'"></span><span style="float: right;" class="fb-like" data-href="https://www.facebook.com/pages/Likeme/' + page[0] +'" data-send="false" data-layout="button_count" data-width="450" data-show-faces="false" data-font="arial"></span>'               

	var page_div = document.createElement("div");
	page_div.className = 'text_div';		
	page_div.style.height = "120px";
	page_div.style.maxHeight = "93px";
	page_div.style.overflowY='auto';
	page_div.style.padding="0px";
	page_div.id = page[0];
	page_div.style.width = "300px";
	page_div.style.maxWidth = "300px";
	//page_div.innerHTML = "something about the page";
	
	
	cell2.appendChild(page_div);
	get_description(page[0]);
	//page_div.innerHTML = get_description(page[0]);
	//cell2.innerHTML = name_link(matches[user_number][0]) + print_stats(matches[user_number][0]);
	//alert(JSON.stringify(page));

	for (var k=0;k<3;k++)
	{ 
		var cell=row1.insertCell(-1);
		cell.className = 'like_td';
		cell.style.padding="0px";
		cell.style.maxHeight="40px";
		try
		{
			cell.innerHTML = picture_link(page[1][1][k],60);
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
			cell.innerHTML = picture_link(page[1][1][k+3],60);
		}
		catch(err)
		{
		}
	}
}

function get_description(page_id)
{
  var flickerAPI = "http://graph.facebook.com/" + page_id;
  var api_data = $.getJSON( flickerAPI, {
    tags: "mount rainier",
    tagmode: "any",
    format: "json"
  })
  .done(function( data ) {
  	//alert(data.description);
  	//alert(data.description);
  	text_div = document.getElementById(page_id);
  	html = "";
  	if (data.about) {html = data.about;}
  	if (data.description) {html = data.description;}  	
  	text_div.innerHTML = '<i><font color="grey">' + html + '</i></font>';
  	
  	like_id =  'l' + page_id
  	like_td = document.getElementById(like_id);
  	like_td.innerHTML = data.name.trunc(25);
  	//like_div.appendChild = name_div;
  });
}

function load_page_table()
{
	/*var table = document.getElementById("matche_table");
	var matches = document.getElementById("matche_table").getAttribute("data-matches");
	matches = jQuery.parseJSON(matches);
	$("body").data("current_matches", matches);*/
	
	var table = document.getElementById("page_table");
	pages = $('#page_table').data('pages');
	$("body").data("current_pages", pages);
	for (var i=0;i<7;i++)
	{ 
		add_page_row(pages);
		//setTimeout(function(){add_page_row(pages)},40);
	}
	return 1


}





function picture_link(id,size)
{
    size = size.toString(); //resolution is 120px
    id = id.toString();
    html = "<a href=\"http://www.facebook.com/" + id + "\"target=\"_blank\"><img style=\"border-radius: 5px;\"src=\"https://graph.facebook.com/" + id + "/picture?width=" + size + "&height=" + size + "\" width=" + size + " height=" + size + "></a>"
    return html;
}

function name_link(user)
{
    html = "<a href=\"http://www.facebook.com/" + user.id.toString() + "\"target=\"_blank\">" + user.name + "</a>";
    return html;
}

function print_stats(user)
{

    var location = "";
    var hometown = "";
    var html = "";
    if(user.gender != null){html += ", " + user.gender;}
    if(user.age != null){html += ", " + user.age;}
    if(user.relationship_status != null){html += ", " + user.relationship_status;}
        
    if (user.location != null){   	
    	location = user.location;
    	location = JSON.stringify(location).replace(/\\/g,'').replace(/=>/g,":");
    	if(location[0]== '"') {location = location.slice(1,-1)};
    	location = jQuery.parseJSON(location);
    	html += ", " + location.name;
    	}
    else if(user.hometown != null){
    	hometown = user.hometown;
    	hometown = JSON.stringify(hometown).replace(/\\/g,'').replace(/=>/g,":");
    	if(hometown[0]== '"') {hometown = hometown.slice(1,-1)};
    	hometown = jQuery.parseJSON(hometown);
    	html += ", " + hometown.name;
    	}
        
    return html;
}

function postToFeed() {
  	var current_matches = $("body").data("current_matches");
  	//alert(current_matches[0][0].name);
  	var list = {};
  	for(var i=0;i<3;i++)
  	{
  		var key = (i+1).toString();
  		key = key + ")";
  		var user_link = {};
  		user_link["text"] = current_matches[i][0].name+" "+current_matches[i][2]+"% Like me" ;
  		user_link["href"] = "http://www.facebook.com/" + current_matches[i][0].id;
  		list[key] = user_link;
  	}
  	//alert($("body").data("current_matches"));
	//var list = { "1) ":{text: "jenia 90% likeable :))", href:'http://www.facebook.com/100001439566738'} , "lastName":"Doe" }
	//list["2)"] = "ffffs"
    // calling the API ...
    var obj = {
      method: 'feed',
      redirect_uri: 'http://like-me.info/',
      link: 'http://www.like-me.info/',
      picture: 'http://www.rt23.com/Scenery/images/birds/blue_jay.gif',
      name: 'Like me',
      caption: 'my best matches are:',
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

function postPagesToFeed() {
	//alert('fff');
  	var current_pages = $("body").data("current_pages");
  	//alert(current_pages);
  	//alert(current_pages[2][0]);
  	var list = {};
  	for(var i=0;i<4;i++)
  	{
  		var key = (i+1).toString();
  		key = key + ")";
  		var page_link = {};
  		//var name=document.getElementById("l"+current_pages[i][0]).innerText;
  		//alert(name.innerText);
  		page_link["text"] = document.getElementById("l"+current_pages[i][0]).innerText;
  		page_link["href"] = "http://www.facebook.com/" + current_pages[i][0];
  		list[key] = page_link;
  	}
  	//alert($("body").data("current_matches"));
	//var list = { "1) ":{text: "jenia 90% likeable :))", href:'http://www.facebook.com/100001439566738'} , "lastName":"Doe" }
	//list["2)"] = "ffffs"
    // calling the API ...
    var obj = {
      method: 'feed',
      redirect_uri: 'http://like-me.info/',
      link: 'http://www.like-me.info/',
      picture: 'http://www.rt23.com/Scenery/images/birds/blue_jay.gif',
      name: 'Like me',
      caption: 'recommended for me:',
      //description: "some useless words",
      properties: list,
    };

    function callback(response) { //maybe do it ['post_id'] exist...
    if (response['post_id']) {document.getElementById('notice').innerHTML = "successfully posted to feed"}
      //document.getElementById('msg').innerHTML = "successfully posted to feed";
      //document.getElementById('msg').innerHTML = "Post ID: " + response['post_id'];
    }

    FB.ui(obj, callback);
}

