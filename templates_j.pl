use strict;

use constant GLOBAL_HEAD_TEMPLATE => q{

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title><var TITLE></title>
<meta http-equiv="Content-Type"  content="text/html;charset=<var CHARSET>" />
<link rel="stylesheet" type="text/css" href="toothpaste.css" title="Toothpaste" />
<link rel="alternate stylesheet" type="text/css" href="futaba.css" title="Futaba" />
<link rel="shortcut icon" href="favicon.ico" />
<script type="text/javascript" src="kareha.js"></script>
<script type="text/javascript">script_name=<var $self></script>
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
<script type="text/javascript">write_stylesheet_links(" ","stylelink")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:set_manager()" class="managerlink">管理用</a>
</span>

</div>

<div class="threadarea">

<div class="title"><var TITLE></div>

<a name="menu"></a>
<div class="threadlist">
<loop $threads><if $num<=THREADS_LISTED>
	<span class="threadlink">
	<a class="threadlink" href="<var $self>/<var $thread>"><var $num>. 
	<if $num<=THREADS_DISPLAYED></a><a class="threadlist" href="#<var $num>"></if>
	<var $title> (<var $postcount>)</a>
	</span>
</if></loop>

<span class="backloglink"><a class="backloglink" href="<var HTML_BACKLOG>">過去ログはこちら</a></span>

</div>

<div class="threadform">
<form name="threadform" action="<var $self>" method="post">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="password" value="" />
<table><col /><col /><col width="100%" /><tbody><tr valign="top">
	<td><nobr>名前：</nobr></td>
	<td style="white-space:nowrap;"><nobr><input type="text" name="name" size="19" class="threadform" />
		E-mail：<input type="text" name="email" size="19" class="threadform" /></nobr>
	</td>
	<td>
		<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td>Verification:</td>
	<td><input type="text" name="captcha" size="19" class="threadform" />
		<script type="text/javascript">
		document.write('<img class="threadcaptcha" src="'+make_captcha_link(".threadcaptcha")+'" />');
		document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
		</script>
	</td><td></td>
</tr><tr>
</if>
	<td><nobr>タイトル：</nobr></td>
	<td><input type="text" name="title" style="width:100%" class="threadform" /></td>
	<td><input type="submit" value="新規スレッド作成" class="threadform" /></td>
	</tr><tr>
	<td></td>
	<td colspan="2"><textarea name="comment" cols="64" rows="5" class="threadform"></textarea></td>
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
		省略されました・・全てを読むには<a href="<var $self>/<var $thread>/<var $postnum>">ここ</a>を押してください
		</div></div>
		</if>

		<if $omit and $first>
		</div><div class="replygroup">
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
		<td>名前：</td>
		<td><input type="text" name="name" size="19" class="postform" />
			E-mail： <input type="text" name="email" size="19" class="postform" />
			<input type="submit" value="書き込む" class="postform" />
			<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
		</td>
	</tr><tr>
	<if ENABLE_CAPTCHA>
		<td>Verification:</td>
		<td><input type="text" name="captcha" size="19" class="postform" />
			<script type="text/javascript">
			document.write('<img class="postcaptcha" src="'+make_captcha_link(".postcaptcha")+'" />');
			document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
			</script>
		</td>
	</tr><tr>
	</if>
		<td></td>
		<td><textarea name="comment" cols="64" rows="5" class="postform"></textarea><br /></td>
	</tr><tr>
		<td></td>

		<td><div class="threadlinks">
		<a href="<var $self>/<var $thread>">レスを全部読む</a>
		<a href="<var $self>/<var $thread>/l50">最新レス５０</a>
		<a href="<var $self>/<var $thread>/-100">レス１－１００</a>
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
<a href="<var HTML_SELF>" class="navlink">掲示板に戻る</a>
</span>

<span class="stylebar">
<span class="styletitle">
Board look
</span>
<script type="text/javascript">write_stylesheet_links(" ","stylelink")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:thread_manager()" class="managerlink">管理用</a>
</span>

</div>

<div class="threadarea">

<div class="title"><var TITLE></div>

<div class="oldthreadlist">
<loop $threads>
	<span class="oldthreadlink">
	<a class="oldthreadlink" href="<var $self>/<var $thread>"><var $num>. <var $title> (<var $postcount>)</a>
	<span class="oldmanagelink" style="display:none;">
	( <a class="oldmanagelink" href="<var $self>?task=permasagethread&thread=<var $thread>">Permasage</a>
	| <a class="oldmanagelink" href="<var $self>?task=deletethread&thread=<var $thread>">Delete</a>
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
<a class="navlink" href="<var HTML_SELF>">掲示板に戻る</a>
<a class="navlink" href="<var $self>/<var $thread>">レスを全部読む</a>
<a class="navlink" href="<var $self>/<var $thread>/l50">最新レス５０</a>
<a class="navlink" href="<var $self>/<var $thread>/-100">レス１－１００</a>
<!-- hundred links go here -->
</span>

<span class="stylebar">
<span class="styletitle">
Board look
</span>
<script type="text/javascript">write_stylesheet_links(" ","stylelink")</script>
</span>

<span class="managerbar">
<span class="styletitle">
Admin
</span>
<a href="javascript:set_manager()" class="managerlink">管理用</a>
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
<input type="hidden" name="thread" value="<var $thread>" class="postform" />
<input type="hidden" name="password" value="" />
<table><tbody><tr>
	<td>名前：</td>
	<td><input type="text" name="name" size="19" class="postform" />
		E-mail： <input type="text" name="email" size="19" class="postform" />
		<input type="submit" value="書き込む" class="postform" />
		<if FORCED_ANON><small>(Anonymous posting is being enforced)</small></if>
	</td>
</tr><tr>
<if ENABLE_CAPTCHA>
	<td>Verification:</td>
	<td><input type="text" name="captcha" size="19" class="postform" />
		<script type="text/javascript">
		document.write('<img class="postcaptcha" src="'+make_captcha_link(".postcaptcha")+'" />');
		document.write('<input type="hidden" name="key" value="'+captcha_key+'" />');
		</script>
	</td>
</tr><tr>
</if>
	<td></td>
	<td><textarea name="comment" cols="64" rows="5" class="postform" ></textarea><br /></td>
</tr></tbody></table>
</form>
<script type="text/javascript">with(document.postform<var $thread>) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>
</div>
</div>

}.GLOBAL_FOOT_TEMPLATE;



use constant REPLY_TEMPLATE => q{

<div class="reply">

<div class="deletebutton">[<a href="javascript:delete_post(<var $thread>,<var $num>)">削除</a>]</div>

<div class="replyheader">
<span class="replynum"><var $num></span>
名前：
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
use constant S_UNJUST => '不正な投稿をしないで下さい(post)';								# Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOTEXT => '何か書いて下さい';							# Returns error for no text entered in to title/comment
use constant S_NOTITLE => 'Error: No title entered.';							# Returns error for no title entered
use constant S_TOOLONG => '本文が長すぎますっ！';							# Returns error for too many characters in a given field
use constant S_TOOMANYLINES => 'Error: Too many lines.';							# Returns error for too many characters in a given field
use constant S_UNUSUAL => '異常です';							# Returns error for abnormal reply? (this is a mystery!)
use constant S_THREADCOLL => 'Error: Somebody else tried to post a thread at the same time. Try again.';		# If two people create threads during the same second
use constant S_PROXY => 'Error: Proxy detected on port %d.';						# Returns error for proxy detection.
use constant S_NOTHREADERR => 'スレッドがありません';				# Returns error when a non-existant thread is accessed
use constant S_THREADLOCKED => 'Error: Thread is locked.';				# Returns error when a non-existant thread is accessed
use constant S_BADDELPASS => '該当記事が見つからないかパスワードが間違っています';						# Returns error for wrong password (when user tries to delete file)
use constant S_NOTWRITE => 'Error: Cannot write to directory.';						# Returns error when the script cannot write to the directory, the chmod (777) is wrong

1;
