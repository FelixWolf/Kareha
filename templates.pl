use strict;

use constant GLOBAL_HEAD_TEMPLATE => q{

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title><var TITLE></title>
<meta http-equiv="Content-Type"  content="text/html;charset=<var CHARSET>" />
<link rel="stylesheet" type="text/css" href="toothpaste.css" title="Toothpaste" />
<link rel="alternate stylesheet" type="text/css" href="futaba.css" title="Futaba" />
<link rel="alternate stylesheet" type="text/css" href="headline.css" title="Headline" />
<link rel="shortcut icon" href="favicon.ico" />
<script type="text/javascript" src="kareha.js"></script>
<script type="text/javascript">script_name="<var $self>;"</script>
</head><body>
};



use constant GLOBAL_FOOT_TEMPLATE => q{

<div class="footer">
- <a href="http://wakaba.c3.cx/">kareha</a>
+ <a href="http://wakaba.c3.cx/">wakaba</a>
-
</div>
</body></html>
};




use constant MAIN_PAGE_TEMPLATE => GLOBAL_HEAD_TEMPLATE.q{

<div class="topbar">

<span class="stylebar">
<span class="styletitle">
Board look
</span>
<script type="text/javascript">write_stylesheet_links(" ")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:set_manager()">Manage</a>
</span>

</div>

<div class="threadarea">

<div class="title"><var TITLE></div>

<a name="menu"></a>
<div class="threadlist">
<loop $threads><if $num<=THREADS_LISTED>
	<span class="threadlink">
	<a href="<var $self>/<var $thread>"><var $num>. 
	<if $num<=THREADS_DISPLAYED></a><a href="#<var $num>"></if>
	<var $title> (<var $postcount>)</a>
	</span>
</if></loop>

<span class="backloglink"><a href="<var HTML_BACKLOG>">All threads</a></span>

</div>

<div class="threadform">
<form name="threadform" action="<var $self>" method="post">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="password" value="" />
<table><col /><col /><col width="100%" /><tbody><tr valign="top">
	<td>Name:</td>
	<td style="white-space:nowrap;"><nobr><input type="text" name="name" size="19" />
		E-mail: <input type="text" name="email" size="19" /></nobr>
	</td>
	<td>
		<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td>Verification:</td>
	<td><input type="text" name="captcha" size="19" />
		<script type="text/javascript">
		document.write('<img class="threadcaptcha" src="'+make_captcha_link(".threadcaptcha")+'" />');
		document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
		</script>
	</td><td></td>
</tr><tr>
</if>
	<td>Title:</td>
	<td><input type="text" name="title" style="width:100%" /></td>
	<td><input type="submit" value="Create new thread" /></td>
	</tr><tr>
	<td></td>
	<td colspan="2"><textarea name="comment" cols="64" rows="5"></textarea></td>
</tr></tbody></table>
</form>
<script type="text/javascript">with(document.threadform) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>
</div>

</div>

<loop $threads><if $posts>
	<a name="<var $num>"></a>
	<if $permasage><div class="permasagearea"></if>
	<if !$permasage><div class="summaryarea"></if>
	<div class="threadtitle"><var $title> <span class="titlepostcount">(<var $postcount><if $permasage>, permasaged</if>)</span></div>

	<div class="threadnavigation">
	<a href="#menu" title="Jump to thread list">&#9632;</a>
	<a href="#<var $prev>" title="Jump to previous thread">&#9650;</a>
	<a href="#<var $next>" title="Jump to next thread">&#9660;</a>
	</div>

	<div class="allreplies">
	<div class="replygroup">

	<loop $posts>
		<var $reply>

		<if $abbrev>
		</div><div class="replyabbrev">
		Post too long, click <a href="<var $self>/<var $thread>/<var $postnum>">here</a> to view.
		</div></div>
		</if>

		<if $omit and $first>
		</div><div class="repliesomitted"></div><div class="replygroup">
		</if>
		</loop>

		</div>
	</div>

	<div class="postform">
	<form name="postform<var $thread>" action="<var $self>" method="post">
	<input type="hidden" name="task" value="post" />
	<input type="hidden" name="thread" value="<var $thread>" />
	<input type="hidden" name="password" value="" />
	<table><tbody><tr valign="top">
		<td>Name:</td>
		<td><input type="text" name="name" size="19" />
			E-mail: <input type="text" name="email" size="19" />
			<input type="submit" value="Reply" />
			<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
		</td>
	</tr><tr>
	<if ENABLE_CAPTCHA>
		<td>Verification:</td>
		<td><input type="text" name="captcha" size="19" />
			<script type="text/javascript">
			document.write('<img class="postcaptcha" src="'+make_captcha_link(".postcaptcha")+'" />');
			document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
			</script>
		</td>
	</tr><tr>
	</if>
		<td></td>
		<td><textarea name="comment" cols="64" rows="5"></textarea><br /></td>
	</tr><tr>
		<td></td>

		<td><div class="threadlinks">
		<a href="<var $self>/<var $thread>">Entire thread</a>
		<a href="<var $self>/<var $thread>/l50">Last 50 replies</a>
		<a href="<var $self>/<var $thread>/-100">First 100 replies</a>
		</div></td>
	</tr></tbody></table>
	</form>
	<script type="text/javascript">with(document.postform<var $thread>) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>

	</div>
	</div>
</if></loop>

}.GLOBAL_FOOT_TEMPLATE;



use constant BACKLOG_PAGE_TEMPLATE => GLOBAL_HEAD_TEMPLATE.q{

<div class="topbar">

<span class="navbar">
<span class="navtitle">
Navigation
</span>
<a href="<var HTML_SELF>">Return</a>
</span>

<span class="stylebar">
<span class="styletitle">
Board look
</span>
<script type="text/javascript">write_stylesheet_links(" ")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:thread_manager()">Manage</a>
</span>

</div>

<div class="threadarea">

<div class="title"><var TITLE></div>

<div class="oldthreadlist">
<loop $threads>
	<span class="oldthreadlink">
	<a href="<var $self>/<var $thread>"><var $num>. <var $title> (<var $postcount>)</a>
	<span class="oldmanagelink" style="display:none;">
	( <a href="<var $self>?task=permasagethread&thread=<var $thread>">Permasage</a>
	| <a href="<var $self>?task=deletethread&thread=<var $thread>">Delete</a>
	)</span>
	</span>
</loop>
</div>

</div>

}.GLOBAL_FOOT_TEMPLATE;




use constant THREAD_HEAD_TEMPLATE => GLOBAL_HEAD_TEMPLATE.q{

<div class="topbar">

<span class="navbar">
<span class="navtitle">
Navigation
</span>
<a href="<var HTML_SELF>">Return</a>
<a href="<var $self>/<var $thread>">Entire thread</a>
<a href="<var $self>/<var $thread>/l50">Last 50 replies</a>
<a href="<var $self>/<var $thread>/-100">First 100 replies</a>
<!-- hundred links go here -->
</span>

<span class="stylebar">
<span class="styletitle">
Board look
</span>
<script type="text/javascript">write_stylesheet_links(" ")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:set_manager()">Manage</a>
</span>

</div>

<div class="replyarea">

<div class="threadtitle"><var $title></div>

<div class="allreplies">
<div class="replygroup">
};



use constant THREAD_FOOT_TEMPLATE => q{

</div>
</div>

<div class="postform">
<form name="postform<var $thread>" action="<var $self>" method="post">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="thread" value="<var $thread>" />
<input type="hidden" name="password" value="" />
<table><tbody><tr>
	<td>Name:</td>
	<td><input type="text" name="name" size="19" />
		E-mail: <input type="text" name="email" size="19" />
		<input type="submit" value="Reply" />
		<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td>Verification:</td>
	<td><input type="text" name="captcha" size="19" />
		<script type="text/javascript">
		document.write('<img class="postcaptcha" src="'+make_captcha_link(".postcaptcha")+'" />');
		document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
		</script>
	</td>
</tr><tr>
</if>
	<td></td>
	<td><textarea name="comment" cols="64" rows="5" ></textarea><br /></td>
</tr></tbody></table>
</form>
<script type="text/javascript">with(document.postform<var $thread>) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>
</div>
</div>

}.GLOBAL_FOOT_TEMPLATE;



use constant REPLY_TEMPLATE => q{

<div class="reply">

<div class="deletebutton">[<a href="javascript:delete_post(<var $thread>,<var $num>)">Del</a>]</div>

<div class="replyheader">
<span class="replynum"><var $num></span>
Name:
<span class="postername"><if $email><a href="mailto:<var $email>"></if><var $name><if $email></a></if></span><if $trip><span class="postertrip"><if $email><a href="mailto:<var $email>"></if><var TRIPKEY><var $trip><if $email></a></if></span></if>

<var $date>
</div>

<div class="replytext"><var $comment></div>

</div>
};



use constant DELETED_TEMPLATE => q{
<div class="deletedreply">
<span class="replynum"><var $num></span>
<span class="deleted">
Post deleted
<if $reason eq 'user'>by user.</if>
<if $reason eq 'mod'>by moderator.</if>
</span>
</div>
};



#
# Error strings
#

use constant S_BADCAPTCHA => 'Error: Wrong verification code entered.';					# Returns error when the captcha is wrong
use constant S_UNJUST => 'Error: Unjust POST.';								# Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOTEXT => 'Error: No text entered.';							# Returns error for no text entered in to title/comment
use constant S_NOTITLE => 'Error: No title entered.';							# Returns error for no title entered
use constant S_TOOLONG => 'Error: Field too long.';							# Returns error for too many characters in a given field
use constant S_TOOMANYLINES => 'Error: Too many lines.';							# Returns error for too many characters in a given field
use constant S_UNUSUAL => 'Error: Abnormal reply.';							# Returns error for abnormal reply? (this is a mystery!)
use constant S_THREADCOLL => 'Error: Somebody else tried to post a thread at the same time. Try again.';		# If two people create threads during the same second
use constant S_PROXY => 'Error: Proxy detected on port %d.';						# Returns error for proxy detection.
use constant S_NOTHREADERR => 'Error: Thread specified does not exist.';				# Returns error when a non-existant thread is accessed
use constant S_THREADLOCKED => 'Error: Thread is locked.';				# Returns error when a non-existant thread is accessed
use constant S_BADDELPASS => 'Error: Password incorrect.';						# Returns error for wrong password (when user tries to delete file)
use constant S_NOTWRITE => 'Error: Cannot write to directory.';						# Returns error when the script cannot write to the directory, the chmod (777) is wrong



1;
