use strict;

BEGIN { require 'wakautils.pl'; }



#
# Interface strings
#

use constant S_NAVIGATION => 'Navigation';
use constant S_RETURN => 'Return';
use constant S_ENTIRE => 'Entire thread';
use constant S_LAST50 => 'Last 50 replies';
use constant S_FIRST100 => 'First 100 replies';
use constant S_BOARDLOOK => 'Board look';
use constant S_ADMIN => 'Admin';
use constant S_MANAGE => 'Manage';
use constant S_REBUILD => 'Rebuild caches';
use constant S_ALLTHREADS => 'All threads';
use constant S_NAME => 'Name:';
use constant S_EMAIL => 'E-mail:';
use constant S_FORCEDANON => '(Anonymous posting is being enforced)';
use constant S_CAPTCHA => 'Verification:';
use constant S_TITLE => 'Title:';
use constant S_NEWTHREAD => 'Create new thread';
use constant S_REPLY => 'Reply';
use constant S_LISTEXPL => 'Jump to thread list';
use constant S_PREVEXPL => 'Jump to previous thread';
use constant S_NEXTEXPL => 'Jump to next thread';
use constant S_LISTBUTTON => '&#9632;';
use constant S_PREVBUTTON => '&#9650;';
use constant S_NEXTBUTTON => '&#9660;';
use constant S_TRUNC => 'Post too long. Click to view the <a href="%s">whole post</a> or the <a href="%s">entire thread</a>.';
use constant S_PERMASAGED => ', permasaged';
use constant S_POSTERNAME => 'Name:';
use constant S_DELETE => 'Del';
use constant S_USERDELETE => 'Post deleted by user.';
use constant S_MODDELETE => 'Post deleted by moderator.';
use constant S_PERMASAGETHREAD => 'Permasage';
use constant S_DELETETHREAD => 'Delete';

#
# Error strings
#

use constant S_BADCAPTCHA => 'Wrong verification code entered.';			# Error message when the captcha is wrong
use constant S_UNJUST => 'Unjust POST.';									# Error message on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOTEXT => 'No text entered.';								# Error message for no text entered in to title/comment
use constant S_NOTITLE => 'No title entered.';							# Error message for no title entered
use constant S_NOTALLOWED => 'Posting not allowed for non-admins.';								# Error message when the posting type is forbidden for non-admins
use constant S_TOOLONG => 'Text field too long.';								# Error message for too many characters in a given field
use constant S_TOOMANYLINES => 'Too many lines in post.';						# Error message for too many characters in a given field
use constant S_UNUSUAL => 'Abnormal reply.';								# Error message for abnormal reply? (this is a mystery!)
use constant S_SPAM => 'Spammers are not welcome here!';					# Error message when detecting spam
use constant S_THREADCOLL => 'Somebody else tried to post a thread at the same time. Please try again.';		# If two people create threads during the same second
use constant S_NOTHREADERR => 'Thread specified does not exist.';		# Error message when a non-existant thread is accessed
use constant S_BADDELPASS => 'Password incorrect.';						# Error message for wrong password (when user tries to delete file)
use constant S_NOTWRITE => 'Cannot write to directory.';					# Error message when the script cannot write to the directory, the chmod (777) is wrong
use constant S_NOTASK => 'Script error; no task speficied.';				# Error message when calling the script incorrectly
use constant S_NOLOG => 'Couldn\'t write to log.txt.';					# Error message when log.txt is not writeable or similar



#
# Templates
#

use constant GLOBAL_HEAD_INCLUDE => q{

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title><if $title><var $title> - </if><const TITLE></title>
<meta http-equiv="Content-Type"  content="text/html;charset=<const CHARSET>" />
<link rel="shortcut icon" href="<var $path>favicon.ico" />

<if RSS_FILE>
<link rel="alternate" title="RSS feed" href="<var $path><const RSS_FILE>" type="application/rss+xml" />
</if>

<loop \@stylesheets>
<link rel="<if !$default>alternate </if>stylesheet" type="text/css" href="<var $path><var $filename>" title="<var $title>" />
</loop>

<script type="text/javascript">var style_cookie="<const STYLE_COOKIE>";</script>
<script type="text/javascript" src="<var $path>kareha.js"></script>
</head>
};



use constant GLOBAL_FOOT_INCLUDE => q{

<const include("include/footer.html")>

<div id="footer">
- <a href="<var $path><const RSS_FILE>">RSS feed</a>
+ <a href="http://wakaba.c3.cx/">kareha</a>
+ <a href="http://wakaba.c3.cx/">wakaba</a>
-
</div>
</body></html>
};




use constant MAIN_PAGE_TEMPLATE => compile_template( GLOBAL_HEAD_INCLUDE.q{
<body class="mainpage">

<const include("include/header.html")>

<div id="topbar">

<div id="stylebar">
<strong><const S_BOARDLOOK></strong>
<loop \@stylesheets>
	<a href="javascript:set_stylesheet('<var $title>')"><var $title></a>
</loop>
</div>

<div id="managerbar">
<strong><const S_ADMIN></strong>
<a href="javascript:set_manager()"><const S_MANAGE></a>
<span class="manage" style="display:none;">
<a href="<var $self>?task=rebuild"><const S_REBUILD></a>
</span>
</div>

</div>

<div id="threads">

<h1><const TITLE></h1>

<a name="menu"></a>
<div id="threadlist">
<loop $threads><if $num<=THREADS_LISTED>
	<span class="threadlink">
	<a href="<var $self>/<var $thread>"><var $num>. 
	<if $num<=THREADS_DISPLAYED></a><a href="#<var $num>"></if>
	<var $title> (<var $postcount>)</a>
	</span>
</if></loop>

<strong><a href="<var $path><const HTML_BACKLOG>"><const S_ALLTHREADS></a></strong>

</div>

<form name="threadform" action="<var $self>" method="post">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="password" value="" />
<table><col /><col /><col width="100%" /><tbody><tr valign="top">
	<td><nobr><const S_NAME></nobr></td>
	<td style="white-space:nowrap;"><nobr>
		<if !FORCED_ANON><input type="text" name="name" size="19" /></if>
		<if FORCED_ANON><input type="text" size="19" disabled="disabled" /><input type="hidden" name="name" /></if>
		<const S_EMAIL> <input type="text" name="email" size="19" /></nobr>
	</td>
	<td>
		<if FORCED_ANON><small><const S_FORCEDANON></small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td><nobr><const S_CAPTCHA></nobr></td>
	<td><input type="text" name="captcha" size="19" />
	<img class="threadcaptcha" src="captcha.pl?selector=.threadcaptcha" />
	</td><td></td>
</tr><tr>
</if>
	<td><nobr><const S_TITLE></nobr></td>
	<td><input type="text" name="title" style="width:100%" /></td>
	<td><input type="submit" value="<const S_NEWTHREAD>" /></td>
	</tr><tr>
	<td></td>
	<td colspan="2"><textarea name="comment" cols="64" rows="5" onfocus="expand_field()" onblur="shrink_field()"></textarea></td>
</tr></tbody></table>
</form>
<script type="text/javascript">with(document.threadform) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>

</div>

<const include("include/mid.html")>

<div id="posts">

<loop $threads><if $posts>
	<a name="<var $num>"></a>
	<if $permasage><div class="sagethread"></if>
	<if !$permasage><div class="thread"></if>
	<h2><var $title> <small>(<var $postcount><if $permasage>, permasaged</if>)</small></h2>

	<div class="threadnavigation">
	<a href="#menu" title="<const S_LISTEXPL>"><const S_LISTBUTTON></a>
	<a href="#<var $prev>" title="<const S_PREVEXPL>"><const S_PREVBUTTON></a>
	<a href="#<var $next>" title="<cibst S_NEXTEXPL>"><const S_NEXTBUTTON></a>
	</div>

	<div class="replies">

	<if $omit><div class="firstreply"></if>
	<if !$omit><div class="allreplies"></if>

	<loop $posts>
		<var $reply>

		<if $abbrev>
		<div class="replyabbrev">
		<var sprintf(S_TRUNC,"$self/$thread/$postnum","$self/$thread/")>
		</div>
		</if>

		<if $omit and $first>
		</div><div class="repliesomitted"></div><div class="finalreplies">
		</if>
	</loop>

	</div>
	</div>

	<form name="postform<var $thread>" action="<var $self>" method="post">
	<input type="hidden" name="task" value="post" />
	<input type="hidden" name="thread" value="<var $thread>" />
	<input type="hidden" name="password" value="" />
	<table><tbody><tr valign="top">
		<td><nobr><const S_NAME></nobr></td>
		<td>
			<if !FORCED_ANON><input type="text" name="name" size="19" /></if>
			<if FORCED_ANON><input type="text" size="19" disabled="disabled" /><input type="hidden" name="name" /></if>
			<const S_EMAIL> <input type="text" name="email" size="19" />
			<input type="submit" value="<const S_REPLY>" />
			<if FORCED_ANON><small><const S_FORCEDANON></small></if>
		</td>
	</tr><tr>
	<if ENABLE_CAPTCHA>
		<td><nobr><const S_CAPTCHA></nobr></td>
		<td><input type="text" name="captcha" size="19" />
		<img class="postcaptcha" src="captcha.pl?selector=.postcaptcha" />
		</td>
	</tr><tr>
	</if>
		<td></td>
		<td><textarea name="comment" cols="64" rows="5" onfocus="expand_field(<var $thread>)" onblur="shrink_field(<var $thread>)"></textarea></td>
	</tr><tr>
		<td></td>

		<td><div class="threadlinks">
		<a href="<var $self>/<var $thread>/"><const S_ENTIRE></a>
		<a href="<var $self>/<var $thread>/l50"><const S_LAST50></a>
		<a href="<var $self>/<var $thread>/-100"><const S_FIRST100></a>
		</div></td>
	</tr></tbody></table>
	</form>
	<script type="text/javascript">with(document.postform<var $thread>) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>

	</div>
</if></loop>

</div>

}.GLOBAL_FOOT_INCLUDE);



use constant THREAD_HEAD_TEMPLATE => compile_template( GLOBAL_HEAD_INCLUDE.q{
<body class="threadpage">

<const include("include/header.html")>

<div id="topbar">

<div id="navbar">
<strong><const S_NAVIGATION></strong>
<a href="<var $path><const HTML_SELF>"><const S_RETURN></a>
<a href="<var $self>/<var $thread>"><const S_ENTIRE></a>
<a href="<var $self>/<var $thread>/l50"><const S_LAST50></a>
<a href="<var $self>/<var $thread>/-100"><const S_FIRST100></a>
<!-- hundred links go here -->
</div>

<div id="stylebar">
<strong><const S_BOARDLOOK></strong>
<loop \@stylesheets>
	<a href="javascript:set_stylesheet('<var $title>')"><var $title></a>
</loop>
</div>

<div id="managerbar">
<strong><const S_ADMIN></strong>
<a href="javascript:set_manager()"><const S_MANAGE></a>
<span class="manage" style="display:none;">
<a href="<var $self>?task=permasagethread&thread=<var $thread>"><const S_PERMASAGETHREAD></a>
<a href="<var $self>?task=deletethread&thread=<var $thread>"><const S_DELETETHREAD></a>
</span>
</div>

</div>

<div id="posts">

<if $permasage><div class="sagethread"></if>
<if !$permasage><div class="thread"></if>
<h2><var $title> <small>(<var $postcount><if $permasage><const S_PERMASAGED></if>)</small></h2>

<div class="replies">
<div class="allreplies">
});



use constant THREAD_FOOT_TEMPLATE => compile_template( q{

</div>
</div>

<form name="postform<var $thread>" action="<var $self>" method="post">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="thread" value="<var $thread>" />
<input type="hidden" name="password" value="" />
<table><tbody><tr>
	<td><nobr><const S_NAME></nobr></td>
	<td>
		<if !FORCED_ANON><input type="text" name="name" size="19" /></if>
		<if FORCED_ANON><input type="text" size="19" disabled="disabled" /><input type="hidden" name="name" /></if>
		<const S_EMAIL> <input type="text" name="email" size="19" />
		<input type="submit" value="<const S_REPLY>" />
		<if FORCED_ANON><small><const S_FORCEDANON></small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td><nobr><const S_CAPTCHA></nobr></td>
	<td><input type="text" name="captcha" size="19" />
		<img class="postcaptcha" src="<var $path>captcha.pl?selector=.postcaptcha" />
	</td>
</tr><tr>
</if>
	<td></td>
	<td><textarea name="comment" cols="64" rows="5" onfocus="expand_field(<var $thread>)" onblur="shrink_field(<var $thread>)"></textarea><br /></td>
</tr></tbody></table>
</form>
<script type="text/javascript">with(document.postform<var $thread>) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>

</div>
</div>

}.GLOBAL_FOOT_INCLUDE);



use constant THREAD_VIEW_TEMPLATE => compile_template( q{
<var $header>
<loop $replies><var $reply></loop>
<var $footer>
});



use constant REPLY_TEMPLATE => compile_template( q{

<div class="reply">

<h3>
<span class="replynum"><a title="Quote post number in reply" href="javascript:insert('&gt;&gt;<var $num>',<var $thread>)"><var $num></a></span>
<const S_POSTERNAME>
<span class="postername"><if $email><a href="mailto:<var $email>"></if><var $name><if $email></a></if></span><if $trip><span class="postertrip"><if $email><a href="mailto:<var $email>"></if><var $trip><if $email></a></if></span></if>
<var $date>
<span class="deletebutton">
<if ENABLE_DELETION>[<a href="javascript:delete_post(<var $thread>,<var $num>)"><const S_DELETE></a>]</if>
<if !ENABLE_DELETION><span class="manage" style="display:none;">[<a href="javascript:delete_post(<var $thread>,<var $num>)"><const S_DELETE></a>]</span></if>
</span>
</h3>

<div class="replytext"><var $comment></div>

</div>
});



use constant DELETED_TEMPLATE => compile_template( q{
<div class="deletedreply">
<h3>
<span class="replynum"><var $num></span>
<if $reason eq 'user'><const S_USERDELETE></if>
<if $reason eq 'mod'><const S_MODDELETE></if>
</h3>
</div>
});



use constant BACKLOG_PAGE_TEMPLATE => compile_template( GLOBAL_HEAD_INCLUDE.q{
<body class="backlogpage">

<const include("include/header.html")>

<div id="topbar">

<div id="navbar">
<strong><const S_NAVIGATION></strong>
<a href="<var $path><const HTML_SELF>"><const S_RETURN></a>
</div>

<div id="stylebar">
<strong><const S_BOARDLOOK></strong>
<loop \@stylesheets>
	<a href="javascript:set_stylesheet('<var $title>')"><var $title></a>
</loop>
</div>

<div id="managerbar">
<strong><const S_ADMIN></strong>
<a href="javascript:set_manager()"><const S_MANAGE></a>
<span class="manage" style="display:none;">
<a href="<var $self>?task=rebuild"><const S_REBUILD></a>
</span>
</div>

</div>

<div id="threads">

<h1><const TITLE></h1>

<div id="oldthreadlist">
<loop $threads>
	<span class="threadlink">
	<a href="<var $self>/<var $thread>"><var $num>. <var $title> (<var $postcount>)</a>
	<span class="manage" style="display:none;">
	( <a href="<var $self>?task=permasagethread&thread=<var $thread>"><const S_PERMASAGETHREAD></a>
	| <a href="<var $self>?task=deletethread&thread=<var $thread>"><const S_DELETETHREAD></a>
	)</span>
	</span>
</loop>
</div>

</div>

}.GLOBAL_FOOT_INCLUDE);



use constant RSS_TEMPLATE => compile_template( q{
<?xml version="1.0" encoding="<const CHARSET>"?>
<rss version="2.0">

<channel>
<title><const TITLE></title>
<link><var $absolute_path><const HTML_SELF></link>

<loop $threads><if $posts>
	<item>
	<title><var $title> (<var $postcount>)</title>
	<link><var $absolute_self>/<var $thread>/</link>
	<guid><var $absolute_self>/<var $thread>/</guid>
	<comments><var $absolute_self>/<var $thread>/</comments>
	<author><var $author></author>
	<description><![CDATA[
		<var $$posts[0]{reply}=~m!<div class="replytext".(.*?)</div!; $1 >
		<if $abbrev><p><small>Post too long, full version <a href="<var $absolute_self>/<var $thread>/">here</a>.</small></p>
		</if>
	]]></description>
	</item>
</if></loop>

</channel>
</rss>
});



use constant ERROR_TEMPLATE => compile_template( GLOBAL_HEAD_INCLUDE.q{
<body class="errorpage">

<const include("include/header.html")>

<div id="topbar">

<div id="navbar">
<strong><const S_NAVIGATION></strong>
<a href="<var escamp($ENV{HTTP_REFERER})>"><const S_RETURN></a>
</div>

<div id="stylebar">
<strong><const S_BOARDLOOK></strong>
<loop \@stylesheets>
	<a href="javascript:set_stylesheet('<var $title>')"><var $title></a>
</loop>
</div>

</div>

<h1><var $error></h1>

<h2><a href="<var escamp($ENV{HTTP_REFERER})>"><const S_RETURN></a></h2>

</body>
}.GLOBAL_FOOT_INCLUDE);


1;
