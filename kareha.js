var script_name;

function get_cookie(name)
{
	with(document.cookie)
	{
		var index=indexOf(name+"=");
		if(index==-1) return '';
		index=indexOf("=",index)+1;
		var endstr=indexOf(";",index);
		if(endstr==-1) endstr=length;
		return unescape(substring(index,endstr));
	}
};

function set_cookie(name,value,days)
{
	if(days)
	{
		var date=new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires="; expires="+date.toGMTString();
	}
	else expires="";
	document.cookie=name+"="+value+expires+"; path=/";
}



function make_password()
{
	var chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	var pass='';

	for(var i=0;i<8;i++)
	{
		var rnd=Math.floor(Math.random()*chars.length);
		pass+=chars.substring(rnd,rnd+1);
	}

	return(pass);
}

function get_password(name)
{
	var pass=get_cookie(name);
	if(pass) return pass;
	return make_password();
}

var manager;

function set_manager()
{
	manager=prompt("Enter management password:");
}

function delete_post(thread,post)
{
	if(confirm("Are you sure you want to delete reply "+post+"?"))
	{
		var script=document.forms[0].action;
		var password=manager?manager:document.forms[0].password.value;

		document.location=script
		+"?task=delete"
		+"&delete="+thread+","+post
		+"&password="+password;
	}
}



function thread_manager()
{
	manager=prompt("Enter management password:");

	var links=document.getElementsByTagName("a");
	for(var i=0;i<links.length;i++)
	{
		if(links[i].className=="oldmanagelink") links[i].href+="&admin="+manager;
	}

	var spans=document.getElementsByTagName("span");
	for(var i=0;i<spans.length;i++)
	{
		if(spans[i].className=="oldmanagelink") spans[i].style.display="";
	}
}



function find_stylesheet_color(selector)
{
	var sheets=document.styleSheets;
	for(var i=0;i<sheets.length;i++)
	if(!sheets[i].disabled)
	{
		var rules=sheets[i].cssRules||sheets[i].rules;
		for(var j=0;j<rules.length;j++)
		if(rules[j].selectorText==selector)
		{
			return(rules[j].style.color);
		}
	}
}

function make_captcha_link(classname)
{
	// this should use the script_name variable to figure out where captcha.pl is
	return(
		'captcha.pl?key='
		+captcha_key
		+'&color='
		+escape(find_stylesheet_color(classname))
	);
}



function set_stylesheet(styletitle)
{
	var links=document.getElementsByTagName("link");
	var found=false;
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title)
		{
			links[i].disabled=true; // IE needs this to work. IE needs to die.
			if(styletitle==title) { links[i].disabled=false; found=true; }
		}
	}
	if(!found) set_preferred_stylesheet();

	if(document.images)
	{
		for(var i=0;i<document.images.length;i++)
		{
			if(document.images[i].getAttribute('class').indexOf('captcha')!=-1)
			{
				document.images[i].src=make_captcha_link("."+document.images[i].getAttribute('class'));
			}
		}
	}
}

function set_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title) links[i].disabled=(rel.indexOf("alt")!=-1);
	}
}

function get_active_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title&&!links[i].disabled) return title;
	}
}

function get_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&rel.indexOf("alt")==-1&&title) return title;
	}
	return null;
}

function write_stylesheet_links(separator,classname)
{
	var links=document.getElementsByTagName("link");
	var first=true;
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title)
		{
			if(separator&&!first) document.write(separator);
			document.write('<a href="javascript:set_stylesheet(\''+title+'\')"');
			if(classname) document.write(' class="'+classname+'"');
			document.write('>'+title+'</a>');
			first=false;
		}
	}
}

/*window.onload=function(e)
{
	var cookie=get_cookie("karehastyle");
	var title=cookie?cookie:get_preferred_stylesheet();
	set_stylesheet(title);
}*/

window.onunload=function(e)
{
	var title=get_active_stylesheet();
	set_cookie("karehastyle",title,365);
}

var cookie=get_cookie("karehastyle");
var title=cookie?cookie:get_preferred_stylesheet();
set_stylesheet(title);

var captcha_key=make_password();
