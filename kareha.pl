#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use Data::Dumper;
use Fcntl ':flock';

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'config_defaults.pl'; }
BEGIN { require 'templates.pl'; }
BEGIN { require 'captcha.pl'; }
BEGIN { require 'wakautils.pl'; }



#
# Global init
#

no strict;
@stylesheets=get_stylesheets(); # make stylesheets visible to the templates
use strict;

my $query=new CGI;
my $task=$query->param("task");

# Rebuild main page if it doesn't exist
unless(-e HTML_SELF)
{
	build_main_page();
	upgrade_threads();
}

if(!$task)
{
	if($ENV{PATH_INFO}) { show_thread($ENV{PATH_INFO}) }
	else { make_http_forward(HTML_SELF,ALTERNATE_REDIRECT) }
	exit 0;
}

my $log=lock_log();

if($task eq "post")
{
	my $thread=$query->param("thread");
	my $name=$query->param("name");
	my $email=$query->param("email");
	my $title=$query->param("title");
	my $comment=$query->param("comment");
	my $captcha=$query->param("captcha");
	my $password=$query->param("password");

	my $key=$query->cookie("captchakey");

	post_stuff($thread,$name,$email,$title,$comment,$captcha,$key,$password);
}
elsif($task eq "delete")
{
	my $password=$query->param("password");
	my @posts=$query->param("delete");

	delete_stuff($password,@posts);
}
elsif($task eq "deletethread")
{
	die S_BADDELPASS unless($query->param("admin") eq ADMIN_PASS);

	my $thread=$query->param("thread");
	delete_thread($thread);
}
elsif($task eq "permasagethread")
{
	die S_BADDELPASS unless($query->param("admin") eq ADMIN_PASS);

	my $thread=$query->param("thread");
	permasage_thread($thread);
}
elsif($task eq "rebuild")
{
	die S_BADDELPASS unless($query->param("admin") eq ADMIN_PASS);

	build_main_page();
	upgrade_threads();
}
else
{
	die S_NOTASK;
}

release_log($log);

make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);

#
# End of main code
#


sub show_thread($)
{
	my ($path)=@_;
	my ($thread,$range)=$path=~m!/([0-9]+)(.*)!;
	my $filename=RES_DIR.$thread.PAGE_EXT;
	my $modified=(stat $filename)[9];

	if($ENV{HTTP_IF_MODIFIED_SINCE})
	{
		my $ifmod=parse_http_date($ENV{HTTP_IF_MODIFIED_SINCE});
		if($modified<=$ifmod)
		{
			print "Status: 304 Not modified\n\n";
			return;
		}
	}

	my @page=read_array($filename);
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
	print "Date: ".make_date(time(),"http")."\n";
	print "Last-Modified: ".make_date($modified,"http")."\n";
	print "\n";

	my @replies=map { reply=>$_ },@page[$start+1..$end+1];

	print THREAD_VIEW_TEMPLATE->(
		header=>$page[1],
		footer=>$page[$#page],
		replies=>\@replies,
		firstreply=>$page[2],
		start=>$start,
		end=>$end,
	);
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

	write_array(HTML_SELF,MAIN_PAGE_TEMPLATE->(threads=>\@threads));
	write_array(HTML_BACKLOG,BACKLOG_PAGE_TEMPLATE->(threads=>\@threads)) if(HTML_BACKLOG);
	write_array(RSS_FILE,RSS_TEMPLATE->(threads=>\@threads)) if(RSS_FILE);
}

sub abbreviate_reply($)
{
	my ($reply)=@_;

	if($reply=~m!^(.*?<div class="replytext">)(.*?)(</div>.*$)!s)
	{
		my ($prefix,$comment,$postfix)=($1,$2,$3);

		my $abbrev=abbreviate_html($comment,MAX_LINES_SHOWN,APPROX_LINE_LENGTH);
		return $prefix.$abbrev.$postfix if($abbrev);
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

		$threadpage[1]=THREAD_HEAD_TEMPLATE->(%{$thread});
		$threadpage[$num+2]=THREAD_FOOT_TEMPLATE->(%{$thread});

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
		die S_BADCAPTCHA if(find_key($log,$key));
		die S_BADCAPTCHA if(!check_captcha($key,$captcha));
	}

	# proxy check
#	proxy_check($ip) unless($whitelisted);

	# spam check
	die S_SPAM if(spam_check($comment,SPAM_FILE));
	die S_SPAM if(spam_check($title,SPAM_FILE));
	die S_SPAM if(spam_check($name,SPAM_FILE));

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

	# clean up the inputs
	$name=clean_string($name);
	$email=clean_string($email);
	$title=clean_string($title);
	$comment=clean_string($comment);

	# process the tripcode
	($name,$trip)=process_tripcode($name,TRIPKEY,SECRET);

	# insert default values for empty fields
	$name=make_anonymous($ip,$time) unless($name or $trip);

	# create the thread if we are starting a new one
	$thread=make_thread($title,$time,$name.$trip) unless($thread);

	# format the comment
	$comment=format_comment($comment,$thread);

	# generate date
	$date=make_date($time,DATE_STYLE);

	# generate ID code if enabled
	$date.=' ID:'.make_id_code($ip,$time,$email) if(DISPLAY_ID);

	# add the reply to the thread
	my $num=make_reply(ip=>$ip,thread=>$thread,name=>$name,trip=>$trip,email=>$email,
	time=>$time,date=>$date,comment=>$comment);

	# make entry in the log
	add_log($log,$thread,$num,$password,$ip,$key,'');

	# remove old threads from the database
	trim_threads() unless($thread);

	build_main_page();

	# set the name, email and password cookies, plus a new captcha key
	make_cookies(name=>$c_name,email=>$c_email,password=>$c_password,
	captchakey=>make_random_string(8),-charset=>CHARSET,-autopath=>COOKIE_PATH); # yum!
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
	if(ENABLE_WAKABAMARK) { $comment=do_wakabamark($handler,0,@lines) }
	else { $comment="<p>".simple_format($handler,@lines)."</p>" }

	# restore >>1 references hidden in code blocks
	$comment=~s/&gtgt;/&gt;&gt;/g;

	return $comment;
}

sub simple_format($@)
{
	my $handler=shift;
	return join "<br />",map
	{
		my $line=$_;

		# make URLs into links
		$line=~s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}{\<a href="$1"\>$1\</a\>$2}sgi;

		$line=$handler->($line) if($handler);

		$line;
	} @_;
}

sub make_anonymous($$)
{
	my ($ip,$time)=@_;

	return S_ANONAME unless(SILLY_ANONYMOUS);

	my $day=int(($time+9*60*60)/86400); # weird time offset copied from futaba
	srand unpack "N",rc4(null_string(4),"s".$ip.SECRET) if(SILLY_ANONYMOUS==1);
	srand unpack "N",rc4(null_string(4),"s".$ip.$day.SECRET) if(SILLY_ANONYMOUS==2);

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

sub make_id_code($$$)
{
	my ($ip,$time,$email)=@_;

	return EMAIL_ID if($email and DISPLAY_ID==1);

	my $day=int(($time+9*60*60)/86400); # weird time offset copied from futaba
	return encode_base64(rc4(null_string(6),"i".$ip.$day.SECRET),"");
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
	$page[1]=THREAD_HEAD_TEMPLATE->(%meta,thread=>$vars{thread});
	$page[$num+1]=REPLY_TEMPLATE->(%vars,num=>$num);
	$page[$num+2]=THREAD_FOOT_TEMPLATE->(%meta,thread=>$vars{thread});

	write_array($filename,@page);

	return $num;
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

	die S_BADDELPASS unless($password);
	die S_BADDELPASS unless($password eq ADMIN_PASS or match_password($log,$thread,$post,$password));

	my $reason;
	if($password eq ADMIN_PASS) { $reason="mod"; }
	else { $reason="user"; }

	my $filename=RES_DIR.$thread.PAGE_EXT;
	my @page=read_array($filename);
	return unless(@page);

	my %meta=parse_meta_header($page[0]);
	if($post==1 and $meta{postcount}==1)
	{
		delete_thread($thread);
	}
	else
	{
		@page[$post+1]=DELETED_TEMPLATE->(num=>$post,reason=>$reason);
		write_array($filename,@page);
	}
}

sub delete_thread($)
{
	my ($thread)=@_;

	die S_UNUSUAL if($thread=~/[^0-9]/); # check to make sure the thread argument is safe

	unlink RES_DIR.$thread.PAGE_EXT;

	build_main_page();
}

sub permasage_thread($)
{
	my ($thread)=@_;

	die S_UNUSUAL if($thread=~/[^0-9]/); # check to make sure the thread argument is safe

	my $filename=RES_DIR.$thread.PAGE_EXT;
	my @page=read_array($filename);
	my %meta=parse_meta_header($page[0]);

	$meta{permasage}=1;

	$page[0]=make_meta_header(%meta);
	write_array($filename,@page);

	build_main_page();
}



#
# Utility funtions
#

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

sub match_password($$$$)
{
	my ($log,$thread,$post,$password)=@_;
	my $encpass=encode_password($password);

	foreach(@{$log})
	{
		my @data=split /\s*,\s*/;
		return 1 if($data[0]==$thread and $data[1]==$post and $data[2] eq $encpass);
	}
	return 0;
}

sub find_key($$)
{
	my ($log,$key)=@_;

	foreach(@{$log})
	{
		my @data=split /\s*,\s*/;
		return 1 if($data[4] eq $key);
	}
	return 0;
}

sub lock_log()
{
	open LOGFILE,"+>>log.txt" or die S_NOLOG;
	flock LOGFILE,LOCK_EX;
	seek LOGFILE,0,0;

	my @log=grep { /^([0-9]+)/; -e RES_DIR.$1.PAGE_EXT } read_array(\*LOGFILE);

	# should remove MD5 for deleted files somehow
	return \@log;
}

sub release_log(;$)
{
	my ($log)=@_;

	if($log)
	{
		seek LOGFILE,0,0;
		truncate LOGFILE,0;
		write_array(\*LOGFILE,@$log);
	}

	close LOGFILE;
}

sub add_log($$$$$$$)
{
	my ($log,$thread,$post,$password,$ip,$key,$md5)=@_;

	$password=encode_password($password);
	$ip=encode_ip($ip);

	unshift @$log,"$thread,$post,$password,$ip,$key,$md5";
}

sub encode_password($) { return encode_base64(rc4(null_string(6),"p".(shift).SECRET),""); }
sub encode_ip($) { my $iv=make_random_string(8); return $iv.':'.encode_base64(rc4($_[0],"l".$iv.SECRET),""); }



#
# Image handling
#

my $comment=q[

sub get_file_size($)
{
	my ($file)=@_;
	my (@filestats,$size);

	@filestats=stat $file;
	$size=$filestats[7];

#	make_error(S_TOOBIG) if($size>MAX_KB*1024);
#	make_error(S_TOOBIGORNONE) if($size==0); # check for small files, too?

	return($size);
}

sub process_file($$)
{
	my ($file,$time)=@_;
	my ($md5,$md5ctx,$buffer,$thumbnail,$tn_width,$tn_height);
	my %filetypes=FILETYPES;

	# make sure to read file in binary mode on platforms that care about such things
	binmode $file;

	# analyze file and check that it's in a supported format
	my ($ext,$width,$height)=analyze_image($file);

	# do we know about this file type?
	my $known=$width or $filetypes{$ext};

	make_error(S_BADFORMAT) unless($known or ALLOW_UNKNOWN);
	make_error(S_BADFORMAT) if(grep { $_ eq $ext } FORBIDDEN_EXTENSIONS);
	make_error(S_TOOBIG) if(MAX_IMAGE_WIDTH and $width>MAX_IMAGE_WIDTH);
	make_error(S_TOOBIG) if(MAX_IMAGE_HEIGHT and $height>MAX_IMAGE_HEIGHT);
	make_error(S_TOOBIG) if(MAX_IMAGE_PIXELS and $width*$height>MAX_IMAGE_PIXELS);

	# munge names of unknown types
	$ext.=MUNGE_UNKNOWN unless($known);

	my $filebase=$time.sprintf("%03d",rand(1000));
	my $filename=IMG_DIR.$filebase.'.'.$ext;

	# prepare MD5 checksum if the Digest::MD5 module is available
	$md5ctx=Digest::MD5->new if($has_md5);

	# copy file
	open OUTFILE,">>$filename" or make_error(S_NOTWRITE);
	binmode OUTFILE;
	while(read $file,$buffer,1024) # should the buffer be larger?
	{
		print OUTFILE $buffer;
		$md5ctx->add($buffer) if($md5ctx);
	}
	close $file;
	close OUTFILE;

	if($md5ctx) # if we have Digest::MD5, get the checksum
	{
		$md5=$md5ctx->hexdigest();
	}
	else # try using the md5sum command
	{
		my $md5sum=`md5sum $filename`;
		($md5)=$md5sum=~/^([0-9a-f]+)/ unless($?);
	}

	if($md5) # if we managed to generate an md5 checksum, check for duplicate files
	{
		my $match;
#		my $sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE md5=?;") or make_error(S_SQLFAIL);
#		$sth->execute($md5) or make_error(S_SQLFAIL);
#
#		if($match=$sth->fetchrow_hashref())
#		{
#			unlink $filename; # make sure to remove the file
#			make_error(sprintf(S_DUPE,get_reply_link($$match{num},$$match{parent})));
#		}
	}

	# thumbnail

	$thumbnail=THUMB_DIR.$filebase."s.jpg";

	if(!$width) # not an image file
	{
		if($filetypes{$ext}) # externally defined filetype
		{
			my ($tn_ext);

			open THUMBNAIL,$filetypes{$ext};
			binmode THUMBNAIL;
			($tn_ext,$tn_width,$tn_height)=analyze_image(\*THUMBNAIL);
			close THUMBNAIL;

			# was that icon file really there?
			if(!$tn_width) { $thumbnail=undef }
			else { $thumbnail=$filetypes{$ext} }
#				$thumbnail=THUMB_DIR.$filebase."_s.".$tn_ext;
#				make_error(S_NOTWRITE) unless(copy($filetypes{$ext},$thumbnail));
		}
		else
		{
			$thumbnail=undef;
		}
	}
	elsif($width<=MAX_W and $height<=MAX_H) # small enough to display
	{
		$tn_width=$width;
		$tn_height=$height;

		if(THUMBNAIL_SMALL and !STUPID_THUMBNAILING)
		{
			if(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height))
			{
				if(-s $thumbnail >= -s $filename) # is the thumbnail larger than the original image?
				{
					unlink $thumbnail;
					$thumbnail=$filename;
				}
			}
			else { $thumbnail=undef; }
		}
		else { $thumbnail=$filename; }
	}
	else
	{
		$tn_width=MAX_W;
		$tn_height=int(($height*(MAX_W))/$width);

		if($tn_height>MAX_H)
		{
			$tn_width=int(($width*(MAX_H))/$height);
			$tn_height=MAX_H;
		}

		if(STUPID_THUMBNAILING) { $thumbnail=$filename }
		else
		{
			$thumbnail=undef unless(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height));
		}
	}


	if($filetypes{$ext}) # externally defined filetype - keep the name
	{
		$filebase=$file;
		$filebase=~s!^.*[\\/;`]!!; # cut off any directory or shell attack in filename
		$filename=IMG_DIR.$filebase;

		make_error(S_DUPENAME) if(-e $filename); # verify no name clash
	}
	else # generate random filename - fudges the microseconds
	{


	return($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height);
}

];
