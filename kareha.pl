#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use MIME::Base64;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Encode qw(decode);
use Data::Dumper;

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'templates.pl'; }
BEGIN { require 'config_defaults.pl'; }



#
# Global init
#

my @stylesheets=get_stylesheets();

my $query=new CGI;
my $task=$query->param("task");

if(!$task)
{
	if($ENV{PATH_INFO})
	{
		show_thread($ENV{PATH_INFO});
	}
	else
	{
		unless(-e HTML_SELF)
		{
			build_main_page();
			upgrade_threads();
		}

		make_http_forward(HTML_SELF);
	}
}
elsif($task eq "post")
{
	my $thread=$query->param("thread");
	my $name=$query->param("name");
	my $email=$query->param("email");
	my $title=$query->param("title");
	my $comment=$query->param("comment");
	my $captcha=$query->param("captcha");
	my $key=$query->param("key");
	my $password=$query->param("password");

	post_stuff($thread,$name,$email,$title,$comment,$captcha,$key,$password);
}
elsif($task eq "delete")
{
	my ($password,@posts);

	$password=$query->param("password");
	@posts=$query->param("delete");

	delete_stuff($password,@posts);
}
elsif($task eq "deletethread")
{
	my ($thread,$admin);

	$thread=$query->param("thread");
	$admin=$query->param("admin");

	delete_thread($thread,$admin);
}
elsif($task eq "permasagethread")
{
	my ($thread,$admin);

	$thread=$query->param("thread");
	$admin=$query->param("admin");

	permasage_thread($thread,$admin);
}


sub show_thread($)
{
	my ($path)=@_;

	my ($thread,$range)=$path=~m!/([0-9]+)(.*)!;

	my @page=read_array(RES_DIR.$thread.PAGE_EXT);
	die S_NOTHREADERR unless(@page);

	my $posts=@page-3;
	my ($start,$end);

	if($range=~m!/([0-9]*)-([0-9]*)!)
	{
		$start=$1?$1:1;
		$end=$2?$2:$posts;

		$start=$posts if($start>$posts);
		$end=$posts if($end>$posts);
	}
	elsif($range=~m!/l([0-9]+)!i)
	{
		$start=$posts-$1+1;
		$end=$posts;

		$start=1 if($start<0);
	}
	elsif($range=~m!/([0-9]+)!)
	{
		$start=$end=$1;
		$start=$end=$1 if($start==0 or $start>$posts);
	}
	else
	{
		$start=1;
		$end=$posts;
	}

	print "Content-Type: text/html; charset=".CHARSET."\n";
	print "\n";

	print $page[1];
	print @page[$start+1..$end+1];
	print $page[$#page];
}


sub build_main_page()
{
	my @threads=get_threads(1);

	foreach my $thread (@threads)
	{
		last if($$thread{num}>THREADS_DISPLAYED);

		my @threadpage=read_array($$thread{filename});
		my $replies=$$thread{postcount}-1;
		my $omit=$replies-(REPLIES_PER_THREAD);

		$omit=0 if($omit<0);

		my @posts=map {
			my %post;
			my $reply=$threadpage[$_+1];
			my $abbrev=abbreviate_reply($reply);

			$post{postnum}=$_;
			$post{first}=($_==1);
			$post{abbrev}=$abbrev?1:0;
			$post{reply}=$abbrev?$abbrev:$reply;

			\%post;
		} (1,$omit+2..$replies+1);

		$$thread{posts}=\@posts;
		$$thread{omit}=$omit;

		$$thread{next}=$$thread{num}%(THREADS_DISPLAYED)+1;
		$$thread{prev}=($$thread{num}+(THREADS_DISPLAYED)-2)%(THREADS_DISPLAYED)+1;
	}

	write_array(HTML_SELF,make_template(MAIN_PAGE_TEMPLATE,threads=>\@threads));
	write_array(HTML_BACKLOG,make_template(BACKLOG_PAGE_TEMPLATE,threads=>\@threads));
	write_array(RSS_FILE,make_template(RSS_TEMPLATE,threads=>\@threads)) if(RSS_FILE);
}

sub abbreviate_reply($)
{
	my ($reply)=@_;
	my ($lines,$chars,@stack);

	$reply=~m!^(.*?<div class="replytext">)(.*?)(</div>.*$)!s;
	my ($prefix,$comment,$postfix)=($1,$2,$3);

	while($comment=~m!(?:([^<]+)|<(/?)(\w+).*?(/?)>)!g)
	{
		my ($text,$closing,$tag,$implicit)=($1,$2,lc($3),$4);

		if($text) { $chars+=length $text; }
		else
		{
			push @stack,$tag if(!$closing and !$implicit);
			pop @stack if($closing);

			if(($closing or $implicit) and ($tag eq "p" or $tag eq "blockquote" or $tag eq "pre"
			or $tag eq "li" or $tag eq "ol" or $tag eq "ul" or $tag eq "br"))
			{
				$lines+=int($chars/APPROX_LINE_LENGTH)+1;
				$lines++ if($tag eq "p" or $tag eq "blockquote");
				$chars=0;
			}

			if($lines>=MAX_LINES_SHOWN)
			{
 				# check if there's anything left other than end-tags
 				return undef if((substr $comment,pos $comment)=~m!^(?:\s*</\w+>)*$!);

				my $abbrev=$prefix.substr $comment,0,pos $comment;
				while(my $tag=pop @stack) { $abbrev.="</$tag>" }
				$abbrev.=$postfix;

				return $abbrev;
			}
		}
	}

	return undef;
}

sub upgrade_threads()
{
	my @threads=get_threads(1);

	foreach my $thread (@threads)
	{
		my @threadpage=read_array($$thread{filename});

		my $num=$$thread{postcount};

		$threadpage[1]=make_template(THREAD_HEAD_TEMPLATE,%{$thread});
		$threadpage[$num+2]=make_template(THREAD_FOOT_TEMPLATE,%{$thread});

		write_array($$thread{filename},@threadpage);
	}
}



#
# Posting
#

sub post_stuff($$$$$$$)
{
	my ($thread,$name,$email,$title,$comment,$captcha,$key,$password)=@_;
	my ($ip,$host,$trip,$time,$date);

	# get a timestamp for future use
	$time=time();

	# check that the request came in as a POST, or from the command line
	die S_UNJUST if($ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} ne "POST");

	# check for weird characters
	die S_UNUSUAL if($thread=~/[^0-9]/);
	die S_UNUSUAL if(length($thread)>10);
	die S_UNUSUAL if($name=~/[\n\r]/);
	die S_UNUSUAL if($email=~/[\n\r]/);
	die S_UNUSUAL if($title=~/[\n\r]/);

	# check for excessive amounts of text
	die S_TOOLONG if(length($name)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($email)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($title)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($comment)>MAX_COMMENT_LENGTH);

	# check for empty post
	die S_NOTEXT if($comment=~/^\s*$/);
	die S_NOTITLE if($title=~/^\s*$/ and !$thread);

	# find hostname
	$ip=$ENV{REMOTE_ADDR};
	#$host = gethostbyaddr($ip);

	# check captcha
	if(ENABLE_CAPTCHA)
	{
		die S_BADCAPTCHA if($captcha ne make_word($key));
		die S_BADCAPTCHA if(add_key($key));
	}

	# proxy check
#	proxy_check($ip) unless($whitelisted);

	# check if thread exists
	die S_NOTHREADERR if($thread and !-e RES_DIR.$thread.PAGE_EXT);

	# remember cookies
	my $c_name=$name;
	my $c_email=$email;
	my $c_password=$password;

	# kill the name if anonymous posting is being enforced
	if(FORCED_ANON)
	{
		$name='';
		if($email=~/sage/i) { $email='sage'; }
		else { $email=''; }
	}

	# process the tripcode
	($name,$trip)=process_tripcode($name);

	# clean up the inputs
	$name=clean_string($name);
	$email=clean_string($email);
	$title=clean_string($title);
	$comment=clean_string($comment);

	# insert default values for empty fields
	$name=make_anonymous($ip,$time) unless($name or $trip);

	# create the thread if we are starting a new one
	$thread=make_thread($title,$time,$name.TRIPKEY.$trip) unless($thread);

	# format the comment
	$comment=format_comment($comment,$thread);

	# generate date
	$date=make_date($time,DATE_STYLE);

	# generate ID code if enabled
	$date.=' ID:'.make_id_code($ip,$time,$email) if(DISPLAY_ID);

	# add the reply to the thread
	make_reply(ip=>$ip,thread=>$thread,name=>$name,trip=>$trip,email=>$email,
	time=>$time,date=>$date,comment=>$comment,password=>$password);

	# remove old threads from the database
	trim_threads() unless($thread);

	build_main_page();

	# set the name, email and password cookies
	make_cookies(name=>$c_name,email=>$c_email,password=>$c_password); # yum!

	# forward back to the main page
	make_http_forward(HTML_SELF);
}

sub make_word($)
{
	my ($key)=@_;

	srand unpack "N",md5(SECRET.$key);

	return cfg_expand("%W%",
		W => ["%C%%T%","%C%%T%","%C%%X%","%C%%D%%F%","%C%%V%%F%%T%","%C%%D%%F%%U%","%C%%T%%U%","%I%%T%","%I%%C%%T%","%A%"],
		A => ["%K%%V%%K%%V%tion"],
		K => ["b","c","d","f","g","j","l","m","n","p","qu","r","s","t","v","s%P%"],
		I => ["ex","in","un","re","de"],
		T => ["%V%%F%","%V%%E%e"],
		U => ["er","ish","ly","en","ing","ness","ment","able","ive"],
		C => ["b","c","ch","d","f","g","h","j","k","l","m","n","p","qu","r","s","sh","t","th","v","w","y","s%P%","%R%r","%L%l"],
		E => ["b","c","ch","d","f","g","dg","l","m","n","p","r","s","t","th","v","z"],
		F => ["b","tch","d","ff","g","gh","ck","ll","m","n","n","ng","p","r","ss","sh","t","tt","th","x","y","zz","r%R%","s%P%","l%L%"],
		P => ["p","t","k","c"],
		Q => ["b","d","g"],
		L => ["b","f","k","p","s"],
		R => ["%P%","%Q%","f","th","sh"],
		V => ["a","e","i","o","u"],
		D => ["aw","ei","ow","ou","ie","ea","ai","oy"],
		X => ["e","i","o","aw","ow","oy"]
	);
}

sub proxy_check($)
{
	my ($ip)=@_;

	for my $port (PROXY_CHECK)
	{
		# needs to be implemented
		# die sprintf S_PROXY,$port);
	}
}

sub process_tripcode($)
{
	my ($name,$hash)=@_;

	if($name=~/^([^\#!]*)[\#!](.*)$/)
	{
		my ($namepart,$trippart)=($1,$2);
		my ($normtrip,$sectrip,$trip);

		if($trippart=~/^([^\#!]*)[\#!]+(.*)$/) { $normtrip=$1; $sectrip=$2; }
		else { $normtrip=$trippart; }

		if($normtrip)
		{
			my $salt;
			($salt)=($normtrip."H.")=~/^.(..)/;
			$salt=~s/[^\.-z]/./g;
			$salt=~tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/; 
			$trip.=substr crypt($normtrip,$salt),-10;
		}

		if($sectrip)
		{
			$trip.=TRIPKEY if($normtrip);
			$trip.=TRIPKEY.substr md5_base64(SECRET.$sectrip),0,8;
		}

		return ($namepart,$trip);
	}

	return ($name,"");
}


sub clean_string($)
{
	my ($str)=@_;

	# $str=~s/^\s*//; # remove preceeding whitespace
	# $str=~s/\s*$//; # remove traling whitespace

	$str=~s/&/&amp;/g;
	$str=~s/\</&lt;/g;
	$str=~s/\>/&gt;/g;
	$str=~s/"/&quot;/g; #"
	$str=~s/'/&#039;/g;
	$str=~s/,/&#44;/g;

	# repair unicode entities
	$str=~s/&amp;(\#[0-9]+;)/&$1/g;

	return $str;
}

sub format_comment($$)
{
	my ($comment,$thread)=@_;

	# fix newlines
	$comment=~s/\r\n/\n/g;
	$comment=~s/\r/\n/g;

	# hide >>1 references from the quoting code
	$comment=~s/&gt;&gt;([0-9\-]+)/&gtgt;$1/g;

	my $handler=sub # fix up >>1 references
	{
		my $line=shift;
		$line=~s!&gtgt;([0-9\-]+)!\<a href="$ENV{SCRIPT_NAME}/$thread/$1"\>&gt;&gt;$1\</a\>!gm;
		return $line;
	};

	my @lines=split /\n/,$comment;
	if(ENABLE_WAKABAMARK) { $comment=do_blocks($handler,0,@lines) }
	else { $comment="<p>".do_spans($handler,@lines)."</p>" }

	# restore >>1 references hidden in code blocks
	$comment=~s/&gtgt;/&gt;&gt;/g;

	return $comment;
}

sub do_blocks($@)
{
	my ($handler,$simplify,@lines)=@_;
	my $res;

	while(defined($_=$lines[0]))
	{
		if(/^\s*$/) { shift @lines; } # skip empty lines
		elsif(/^(1\.|[\*\+\-]) .*/) # lists
		{
			my ($tag,$re,$html);

			if($1 eq "1.") { $tag="ol"; $re=qr/[0-9]+\./; }
			else { $tag="ul"; $re=qr/\Q$1\E/; }

			while($lines[0]=~/^($re)(?: |\t)(.*)/)
			{
				my $spaces=(length $1)+1;
				my @item=($2);
				shift @lines;

				while($lines[0]=~/^(?: {1,$spaces}|\t)(.*)/) { push @item,$1; shift @lines }
				$html.="<li>".do_blocks($handler,1,@item)."</li>";
			}
			$res.="<$tag>$html</$tag>";
		}
		elsif(/^(?:    |\t).*/) # code sections
		{
			my @code;
			while($lines[0]=~/^(?:    |\t)(.*)/) { push @code,$1; shift @lines; }
			$res.="<pre><code>".(join "<br />",@code)."</code></pre>";
		}
		elsif(/^&gt;.*/) # quoted sections
		{
			my @quote;
			while($lines[0]=~/^(&gt;.*)/) { push @quote,$1; shift @lines; }
			$res.="<blockquote>".do_spans($handler,@quote)."</blockquote>";

			#while($lines[0]=~/^&gt;(.*)/) { push @quote,$1; shift @lines; }
			#$res.="<blockquote>".do_blocks($handler,@quote)."</blockquote>";
		}
		else # normal paragraph
		{
			my @text;
			while($lines[0]!~/^(?:\s*$|1\. |[\*\+\-] |&gt;|    |\t)/) { push @text,shift @lines; }
			if(!defined($lines[0]) and $simplify) { $res.=do_spans($handler,@text) }
			else { $res.="<p>".do_spans($handler,@text)."</p>" }
		}
		$simplify=0;
	}
	return $res;
}

sub do_spans($@)
{
	my $handler=shift;
	return join "<br />",map
	{
		my $line=$_;
		my @codespans;

		# hide <code> sections
		$line=~s{(`+)([^<>]+?)\1}{push @codespans,$2; "<code></code>"}ge if(ENABLE_WAKABAMARK);

		# make URLs into links
		$line=~s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}{\<a href="$1"\>$1\</a\>$2}sgi;

		# do <strong>
		$line=~s{([^0-9a-zA-Z\*_]|^)(\*\*|__)([^<>\s\*_](?:[^<>]*?[^<>\s\*_])?)\2([^0-9a-zA-Z\*_]|$)}{$1<strong>$3</strong>$4}g if(ENABLE_WAKABAMARK);

		# do <em>
		$line=~s{([^0-9a-zA-Z\*_]|^)(\*|_)([^<>\s\*_](?:[^<>]*?[^<>\s\*_])?)\2([^0-9a-zA-Z\*_]|$)}{$1<em>$3</em>$4}g if(ENABLE_WAKABAMARK);

		$line=$handler->($line) if($handler);

		# fix up <code> sections
		$line=~s{<code></code>}{"<code>".(shift @codespans)."</code>"}ge if(ENABLE_WAKABAMARK);

		$line;
	} @_;
}

sub make_anonymous($$)
{
	my ($ip,$time)=@_;

	return S_ANONAME unless(SILLY_ANONYMOUS);

	my @gmt=gmtime $time+9*60*60; # weird time offset copied from futaba
	my $date=sprintf '%04d%02d%02d',$gmt[5]+1900,$gmt[4]+1,$gmt[3];

	srand unpack "N",md5(SECRET.$ip) if(SILLY_ANONYMOUS==1);
	srand unpack "N",md5(SECRET.$ip.$date) if(SILLY_ANONYMOUS==2);

	return cfg_expand("%G% %W%",
		W => ["%B%%V%%M%%I%%V%%F%","%B%%V%%M%%E%","%O%%E%","%B%%V%%M%%I%%V%%F%","%B%%V%%M%%E%","%O%%E%","%B%%V%%M%%I%%V%%F%","%B%%V%%M%%E%"],
		B => ["B","B","C","D","D","F","F","G","G","H","H","M","N","P","P","S","S","W","Ch","Br","Cr","Dr","Bl","Cl","S"],
		I => ["b","d","f","h","k","l","m","n","p","s","t","w","ch","st"],
		V => ["a","e","i","o","u"],
		M => ["ving","zzle","ndle","ddle","ller","rring","tting","nning","ssle","mmer","bber","bble","nger","nner","sh","ffing","nder","pper","mmle","lly","bling","nkin","dge","ckle","ggle","mble","ckle","rry"],
		F => ["t","ck","tch","d","g","n","t","t","ck","tch","dge","re","rk","dge","re","ne","dging"],
		O => ["Small","Snod","Bard","Billing","Black","Shake","Tilling","Good","Worthing","Blythe","Green","Duck","Pitt","Grand","Brook","Blather","Bun","Buzz","Clay","Fan","Dart","Grim","Honey","Light","Murd","Nickle","Pick","Pock","Trot","Toot","Turvey"],
		E => ["shaw","man","stone","son","ham","gold","banks","foot","worth","way","hall","dock","ford","well","bury","stock","field","lock","dale","water","hood","ridge","ville","spear","forth","will"],
		G => ["Albert","Alice","Angus","Archie","Augustus","Barnaby","Basil","Beatrice","Betsy","Caroline","Cedric","Charles","Charlotte","Clara","Cornelius","Cyril","David","Doris","Ebenezer","Edward","Edwin","Eliza","Emma","Ernest","Esther","Eugene","Fanny","Frederick","George","Graham","Hamilton","Hannah","Hedda","Henry","Hugh","Ian","Isabella","Jack","James","Jarvis","Jenny","John","Lillian","Lydia","Martha","Martin","Matilda","Molly","Nathaniel","Nell","Nicholas","Nigel","Oliver","Phineas","Phoebe","Phyllis","Polly","Priscilla","Rebecca","Reuben","Samuel","Sidney","Simon","Sophie","Thomas","Walter","Wesley","William"],
	);
}

sub make_date($)
{
	my ($time,$style)=@_;

	if($style==0)
	{
		my @ltime=localtime($time);

		return sprintf("%04d-%02d-%02d %02d:%02d",
		$ltime[5]+1900,$ltime[4]+1,$ltime[3],$ltime[2],$ltime[1]);
	}
	elsif($style==1)
	{
		return scalar(localtime($time));
	}
}

sub make_id_code($$$)
{
	my ($ip,$time,$email)=@_;

	return EMAIL_ID if($email and DISPLAY_ID==1);

	my @gmt=gmtime $time+9*60*60; # weird time offset copied from futaba
	my $date=sprintf '%04d%02d%02d',$gmt[5]+1900,$gmt[4]+1,$gmt[3];

	return substr(md5_base64(SECRET.$ip.$date),-8) if(SECURE_ID);
	return substr(crypt(md5_hex($ip.'id'.$date),'id'),-8);
}

sub make_reply(%)
{
	my (%vars)=@_;

	my $filename=RES_DIR.$vars{thread}.PAGE_EXT;
	my @page=read_array($filename);
	my %meta=parse_meta_header($page[0]);

	die S_THREADLOCKED if($meta{locked});

	my $num=$meta{postcount}+1;

	$meta{postcount}++;
	$meta{lasthit}=$vars{time} unless($vars{email}=~/sage/i or $meta{postcount}>=MAX_RES or $meta{permasage}); # bump unless sage, too many replies, or permasage

	$page[0]=make_meta_header(%meta);
	$page[1]=make_template(THREAD_HEAD_TEMPLATE,%meta,thread=>$vars{thread});
	$page[$num+1]=make_template(REPLY_TEMPLATE,%vars,num=>$num);
	$page[$num+2]=make_template(THREAD_FOOT_TEMPLATE,%meta,thread=>$vars{thread});

	write_array($filename,@page);

	add_log($vars{thread},$num,$vars{password},$vars{ip});
}


sub make_thread($$$)
{
	my ($title,$time,$author)=@_;
	my $filename=RES_DIR.$time.PAGE_EXT;

	die S_THREADCOLL if(-e $filename);

	write_array($filename,make_meta_header(title=>$title,postcount=>0,lasthit=>$time,permasage=>0,author=>$author),"","");

	return $time;
}




#
# Deleting
#

sub delete_stuff($@)
{
	my ($password,@posts)=@_;

	foreach my $post (@posts)
	{
		my ($thread,$num)=$post=~/([0-9]+),([0-9]+)/;

		delete_post($thread,$num,$password);
	}

	build_main_page();

	make_http_forward(HTML_SELF);
}

sub trim_threads()
{
	return unless(MAX_THREADS);

	my @threads=get_threads(TRIM_METHOD);

	if(@threads>MAX_THREADS)
	{
		splice @threads,0,MAX_THREADS;

		foreach (@threads) { unlink $$_{filename};  }
	}
}

sub delete_post($$$)
{
	my ($thread,$post,$password)=@_;
	my $logpass=find_password($thread,$post);
	my $encpass=encode_password($password);

	die S_BADDELPASS unless($password);
	die S_BADDELPASS unless($password eq ADMIN_PASS or $encpass eq $logpass);

	my $reason;
	if($password eq ADMIN_PASS) { $reason="mod"; }
	else { $reason="user"; }

	my $filename=RES_DIR.$thread.PAGE_EXT;
	my @page=read_array($filename);
	return unless(@page);

	@page[$post+1]=make_template(DELETED_TEMPLATE,num=>$post,reason=>$reason);

	write_array($filename,@page);
}

sub delete_thread($$)
{
	my ($thread,$admin)=@_;

	die S_BADDELPASS unless($admin eq ADMIN_PASS);
	die S_UNUSUAL if($thread=~/[^0-9]/); # check to make sure the thread argument is safe

	unlink RES_DIR.$thread.PAGE_EXT;

	build_main_page();

	make_http_forward(HTML_SELF);
}

sub permasage_thread($$)
{
	my ($thread,$admin)=@_;

	die S_BADDELPASS unless($admin eq ADMIN_PASS);
	die S_UNUSUAL if($thread=~/[^0-9]/); # check to make sure the thread argument is safe

	my $filename=RES_DIR.$thread.PAGE_EXT;
	my @page=read_array($filename);
	my %meta=parse_meta_header($page[0]);

	$meta{permasage}=1;

	$page[0]=make_meta_header(%meta);
	write_array($filename,@page);

	build_main_page();

	make_http_forward(HTML_SELF);
}




#
# Metadata access utils
#

sub get_threads($)
{
	my ($bumped)=@_;

	my @pages=map {
		open PAGE,$_ or return undef;
		my $head=<PAGE>;
		close PAGE;
		my %meta=parse_meta_header($head);

		my $re=RES_DIR.'([0-9]+)'.PAGE_EXT;
		my ($thread)=$_=~/$re/;

		my $hash={ %meta,thread=>$thread,filename=>$_ };
		$hash;
	} glob(RES_DIR."*".PAGE_EXT);

	if($bumped) { @pages=sort { $$b{lasthit}<=>$$a{lasthit} } @pages; }
	else { @pages=sort { $$b{thread}<=>$$a{thread} } @pages; }

	my $num=1;
	$$_{num}=$num++ for(@pages);

	return @pages;
}

sub parse_meta_header($)
{
	my ($header)=@_;
	my ($code)=$header=~/\<!--(.*)--\>/;
	return () unless $code;
	return %{eval $code};
}

sub make_meta_header(%)
{
	my (%meta)=@_;
	$Data::Dumper::Terse=1;
	$Data::Dumper::Indent=0;
	return '<!-- '.Dumper(\%meta).' -->';
}

sub find_password($$)
{
	my ($thread,$post)=@_;

	foreach(read_log())
	{
		my @data=split /\s*,\s*/;
		return $data[2] if($data[0]==$thread and $data[1]==$post);
	}
	return undef;
}

sub add_log($$$$)
{
	my ($thread,$post,$password,$ip)=@_;

	$password=encode_password($password);
	$ip=encode_ip($ip);

	my @log=read_log();
	unshift @log,"$thread,$post,$password,$ip";
	write_log(@log);
}

sub add_key($)
{
	my ($key)=@_;

	my @keys=read_keys();
	return 1 if(grep { $key eq $_ } @keys);
	push @keys,$key;
	@keys=splice @keys,-(MAX_KEY_LOG) if(@keys>=MAX_KEY_LOG);
	write_keys(@keys);

	return 0;
}

sub read_log() { return grep { /^([0-9]+)/; -e RES_DIR.$1.PAGE_EXT } read_array("log.txt"); }
sub write_log(@) { write_array("log.txt",@_); }
sub read_keys() { read_array("keys.txt"); }
sub write_keys(@) { write_array("keys.txt",@_); }

sub read_array($)
{
	my ($filename)=@_;
	my @array;

	if(open FILE,$filename)
	{
		@array=<FILE>;
		chomp @array;
		close FILE;
	}
	return @array;
}

sub write_array($)
{
	my ($filename,@array)=@_;

	open FILE,">$filename" or die S_NOTWRITE;
	print FILE join "\n",@array;
	close FILE;
}

sub encode_password($) { return substr md5_base64(SECRET.$_[0]),0,8; }
sub encode_ip($) { my $iv=make_iv(); return $iv.'!'.encode_base64(rc4($_[0],md5(SECRET.$iv)),''); }

sub make_iv()
{
	my $iv;
	my $chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

	$iv.=substr $chars,rand length $chars,1 for(0..7);

	return $iv;
}

sub rc4($$)
{
	my ($message,$key)=@_;

	my @k=unpack 'C*',$key;
	my @s=0..255;
	my $y=0;
	for my $x (0..255)
	{
		$y=($k[$x%@k]+$s[$x]+$y)%256;
		@s[$x,$y]=@s[$y,$x];
	}

	my $x,$y;

	my @message=unpack 'C*',$message;
	for(@message)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
		$_^=$s[($s[$x]+$s[$y])%256];
	}
	return pack 'C*',@message;
}

sub cfg_expand($%)
{
	my ($str,%grammar)=@_;
	$str=~s/%(\w+)%/
		my @expansions=@{$grammar{$1}};
		cfg_expand($expansions[rand @expansions],%grammar);
	/ge;
	return $str;
}

sub get_stylesheets()
{
	my $found=0;
	my @stylesheets=map
	{
		my %sheet;

		$sheet{filename}=$_;

		($sheet{title})=m!([^/]+)\.css$!i;
		$sheet{title}=ucfirst $sheet{title};
		$sheet{title}=~s/_/ /g;
		$sheet{title}=~s/ ([a-z])/ \u$1/g;
		$sheet{title}=~s/([a-z])([A-Z])/$1 $2/g;

		if($sheet{title} eq DEFAULT_STYLE) { $sheet{default}=1; $found=1; }
		else { $sheet{default}=0; }

		\%sheet;
	} glob(CSS_DIR."*.css");

	$stylesheets[0]{default}=1 if(@stylesheets and !$found);

	return @stylesheets;
}



#
# Page creation utils
#

sub make_template($%)
{
	my ($src,%vars)=@_;
	my ($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;

	$src=~s/\s+/ /sg;
	$src=~s/^\s+//;
	$src=~s/\s+$//;

	my $port=$ENV{SERVER_PORT}==80?"":":$ENV{SERVER_PORT}";
	$vars{self}=$ENV{SCRIPT_NAME};
	$vars{absolute_self}="http://$ENV{SERVER_NAME}$port$ENV{SCRIPT_NAME}";
	$vars{path}=$self_path;
	$vars{absolute_path}="http://$ENV{SERVER_NAME}$port$self_path";

	my $res=expand_template($src,%vars);

	$res=~s/\n/ /sg;

	return $res;
}

sub expand_template($%)
{
	my ($str,%vars)=@_;
	my ($vardefs,$blocks,$singles);

	$vardefs.="my \$$_=\$vars{$_};" for(keys %vars);

	$blocks=qr(
		\<(if|loop)(?:|\s+([^\>]*))\>
		((?:
			(?>[^\<]+)
		|
			\<(?!/?(?:if|loop)(?:|\s+[^\>]*)\>)
		|
			(??{$blocks})
		)*)
		\</(?:\1)\>
	)x;
	$singles=qr(\<(var)(?:|\s+(.*?)/?)\>);

	$str=~s/(?:$blocks|$singles)/
		my ($btag,$barg,$bdata,$stag,$sarg)=($1,$2,$3,$4,$5);

		if($stag eq 'var')
		{
			eval $vardefs.$sarg;
		}
		elsif($btag eq 'if')
		{
			eval $vardefs.$barg ? expand_template($bdata,%vars) : '';
		}
		elsif($btag eq 'loop')
		{
			join '',map { expand_template($bdata,(%vars,%$_)) } @{eval $vardefs.$barg};
		}
	/sge;

	return $str;
}

sub make_http_forward($)
{
	my ($location)=@_;

	if(ALTERNATE_REDIRECT)
	{
		print "Content-Type: text/html\n";
		print "\n";
		print "<html><head>";
		print '<meta http-equiv="refresh" content="0; url='.$location.'" />';
		print '<script type="text/javascript">document.location="'.$location.'";</script>';
		print '</head><body><a href="'.$location.'">'.$location.'</a></body></html>';
	}
	else
	{
		print "Status: 301 Go West\n";
		print "Location: $location\n";
		print "Content-Type: text/html\n";
		print "\n";
		print '<html><body><a href="'.$location.'">'.$location.'</a></body></html>';
	}
}

sub make_cookies(%)
{
	my (%cookies)=@_;
	my ($cookie);

	foreach my $name (keys %cookies)
	{
		my $value=defined($cookies{$name})?$cookies{$name}:'';
		$value=decode(CHARSET,$value);
		$value=join '',map { my $c=ord($_); sprintf($c>255?'%%u%04x':'%%%02x',$c); } split //,$value;

		my $cookie=$query->cookie(-name=>$name,
		                          -value=>$value,
		                          -expires=>'+14d');

		$cookie=~s/%25/%/g; # repair encoding damage

		print "Set-Cookie: $cookie\n";
	}
}
