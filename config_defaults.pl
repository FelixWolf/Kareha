use strict;

BEGIN {
	sub declared($)
	{
		use constant 1.01; # don't omit this! ...tte iu no ka
		return $constant::declared{"main::".shift};
	}

	# System config
	die S_NOADMIN unless(declared("ADMIN_PASS"));
	die S_NOSECRET unless(declared("SECRET"));

	# Page look
	eval "use constant TITLE => 'Kareha message board'" unless(declared("TITLE"));
	eval "use constant THREADS_DISPLAYED => 10" unless(declared("THREADS_DISPLAYED"));
	eval "use constant THREADS_LISTED => 40" unless(declared("THREADS_LISTED"));
	eval "use constant REPLIES_PER_THREAD => 10" unless(declared("REPLIES_PER_THREAD"));
	eval "use constant S_ANONAME => 'Anonymous'" unless(declared("S_ANONAME"));
	eval "use constant DEFAULT_STYLE => 'Headline'" unless(declared("DEFAULT_STYLE"));

	# Limitations
	eval "use constant MAX_RES => 1000" unless(declared("MAX_RES"));
	eval "use constant MAX_THREADS => 500" unless(declared("MAX_THREADS"));
	eval "use constant MAX_FIELD_LENGTH => 100" unless(declared("MAX_FIELD_LENGTH"));
	eval "use constant MAX_COMMENT_LENGTH => 8192" unless(declared("MAX_COMMENT_LENGTH"));
	eval "use constant MAX_LINES => 100" unless(declared("MAX_LINES"));
	eval "use constant MAX_LINES_SHOWN => 15" unless(declared("MAX_LINES_SHOWN"));
	eval "use constant MAX_KEY_LOG => 1000" unless(declared("MAX_KEY_LOG"));

	# Captcha
	eval "use constant ENABLE_CAPTCHA => 0" unless(declared("ENABLE_CAPTCHA"));

	# Tweaks
	eval "use constant CHARSET => 'utf-8'" unless(declared("CHARSET"));
	eval "use constant PROXY_CHECK => ()" unless(declared("PROXY_CHECK"));
	eval "use constant TRIM_METHOD => 1" unless(declared("TRIM_METHOD"));
	eval "use constant DATE_STYLE => 0" unless(declared("DATE_STYLE"));
	eval "use constant DISPLAY_ID => 1" unless(declared("DISPLAY_ID"));
	eval "use constant SECURE_ID => 1" unless(declared("SECURE_ID"));
	eval "use constant EMAIL_ID => 'Heaven'" unless(declared("EMAIL_ID"));
	eval "use constant SILLY_ANONYMOUS => 0" unless(declared("SILLY_ANONYMOUS"));
	eval "use constant FORCED_ANON => 0" unless(declared("FORCED_ANON"));
	eval "use constant TRIPKEY => '!'" unless(declared("TRIPKEY"));
	eval "use constant ALTERNATE_REDIRECT => 0" unless(declared("ALTERNATE_REDIRECT"));
	eval "use constant ENABLE_WAKABAMARK => 1" unless(declared("ENABLE_WAKABAMARK"));
	eval "use constant APPROX_LINE_LENGTH => 150" unless(declared("APPROX_LINE_LENGTH"));

	# Internal paths and files - might as well leave this alone.
	eval "use constant RES_DIR => 'res/'" unless(declared("RES_DIR"));
	eval "use constant HTML_SELF => 'index.html'" unless(declared("HTML_SELF"));
	eval "use constant HTML_BACKLOG => 'subback.html'" unless(declared("HTML_BACKLOG"));
	eval "use constant RSS_FILE => 'index.rss'" unless(declared("RSS_FILE"));
	eval "use constant CSS_DIR => 'css/'" unless(declared("CSS_DIR"));
	eval "use constant PAGE_EXT => '.html'" unless(declared("PAGE_EXT"));
}

1;
