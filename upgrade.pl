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

print "Content-type: text/html\n\n";
print "<html><body>";

upgrade_replies();

unlink HTML_SELF;

print '<br /><br /><a href="kareha.pl">Click here to rebuild caches</a>';
print "</html></body>";



use constant CONV_REPLY_TEMPLATE => q{

<div class="reply">

<h3>
<var $header>
<span class="deletebutton">[<a href="javascript:delete_post(<var $thread>,<var $num>)">Del</a>]</span>
</h3>

<div class="replytext"><p><var $comment></p></div>

</div>
};

sub upgrade_replies()
{
	my @threads=get_threads(1);
	my $upgraded1=0;
	my $upgraded2=0;
	my $upgraded3=0;

	foreach my $thread (@threads)
	{
		my @threadpage=read_array($$thread{filename});

		my $num=$$thread{postcount};

		for(my $i=2;$i<$num+2;$i++)
		{
			my %reply;
			my $fixed;

			if(%reply=parse_reply($threadpage[$i]))
			{
				$threadpage[$i]=make_template(CONV_REPLY_TEMPLATE,%reply);

				$upgraded1++;
			}

			if($fixed=fix_quotes($threadpage[$i]))
			{
				$threadpage[$i]=$fixed;

				$upgraded2++;
			}

			if($fixed=fix_blockquotes($threadpage[$i]))
			{
				$threadpage[$i]=$fixed;

				$upgraded3++;
			}
		}

		write_array($$thread{filename},@threadpage);
	}

	my $threads=@threads;
	print "$upgraded1+$upgraded2+$upgraded3 replies in $threads threads upgraded.\n";
}

sub parse_reply($)
{
	my ($reply)=@_;

	if($reply=~m!<div class="replyheader">(.*?)</div>\s*<div class="replytext">(.*?)</div>!)
	{
		return (header=>$1,comment=>$2);
	}

	return ();
}

sub fix_quotes($)
{
	my ($reply)=@_;

	$reply=~s!</span>\s+<br />\s+<span class="quoted">!<br />!g;

	if($reply=~s!<span class="quoted">(.*?)</span>!<blockquote>$1</blockquote>!g)
	{
		return $reply;
	}

	return "";
}

sub fix_blockquotes($)
{
	my ($reply)=@_;

	if($reply=~s!</h3>\s+<blockquote>(.*)</blockquote>!</h3><div class="replytext">$1</div>!)
	{
		return $reply;
	}

	return "";
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
