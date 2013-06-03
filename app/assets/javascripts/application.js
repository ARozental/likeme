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

function add_row(matches)
{
var table=document.getElementById("matche_table");

	var user_number = table.rows.length/2;	
	if(matches[user_number][0].id != null)
	{
		var row1=table.insertRow(-1);
		var cell1=row1.insertCell(-1);
		var cell2=row1.insertCell(-1);
		cell1.innerHTML = picture_link(matches[user_number][0].id,120);
		cell1.className = 'face_td';
		cell1.rowSpan="2";
		cell1.style.padding="0px";
		
		//cell2.innerHTML = "<a href=\"http://www.facebook.com/" + matches[user_number][0].id + "\"><img src=\"https://graph.facebook.com/" + matches[user_number][0].id + "/picture?width=120&height=120\" width=" + "120" + " height=" + "120" + "></a>";		
		cell2.innerHTML = name_link(matches[user_number][0]) + print_stats(matches[user_number][0]);
		
		for (var k=0;k<3;k++)
		{ 
			var cell=row1.insertCell(-1);
			cell.className = 'like_td';
			cell.style.padding="0px";
			cell.style.maxHeight="40px";
			try
			{
				cell.innerHTML = picture_link(matches[user_number][1][k],60);
			}
			catch(err)
			{
			}
		}

		var row2=table.insertRow(-1);
		//<td><div class="text_div" style="height: 60px;"><%= @matches[n][0].quotes %></div></td>
		var cell3=row2.insertCell(-1);
		var user_div = document.createElement("div");
		user_div.className = 'text_div';		
		user_div.style.height = "60px";
		user_div.style.maxHeight = "60px";
		user_div.style.overflowY='auto';
		user_div.style.padding="0px";		
		user_div.innerHTML = matches[user_number][0].quotes;
		cell3.appendChild(user_div);
		
		for (var k=0;k<3;k++)
		{ 
			var cell=row2.insertCell(-1);
			cell.className = 'like_td';
			cell.style.padding="0px";
			cell.style.maxHeight="40px";
			try
			{
				cell.innerHTML = picture_link(matches[user_number][1][k+3],60);
			}
			catch(err)
			{
			}
		}
	}

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


