use strict;

BEGIN {
	use constant S_NOADMIN => 'No ADMIN_PASS defined in the configuration';	# Returns error when the config is incomplete
	use constant S_NOSECRET => 'No SECRET defined in the configuration';	# Returns error when the config is incomplete

	# System config
	die S_NOADMIN unless(defined &ADMIN_PASS);
	die S_NOSECRET unless(defined &SECRET);

	# Page look
	eval "use constant TITLE => 'Kareha message board'" unless(defined &TITLE);
	eval "use constant THREADS_DISPLAYED => 10" unless(defined &THREADS_DISPLAYED);
	eval "use constant THREADS_LISTED => 40" unless(defined &THREADS_LISTED);
	eval "use constant REPLIES_PER_THREAD => 10" unless(defined &REPLIES_PER_THREAD);
	eval "use constant S_ANONAME => 'Anonymous'" unless(defined &S_ANONAME);
	eval "use constant DEFAULT_STYLE => 'Headline'" unless(defined &DEFAULT_STYLE);

	# Limitations
	eval "use constant MAX_RES => 1000" unless(defined &MAX_RES);
	eval "use constant MAX_THREADS => 500" unless(defined &MAX_THREADS);
	eval "use constant MAX_FIELD_LENGTH => 100" unless(defined &MAX_FIELD_LENGTH);
	eval "use constant MAX_COMMENT_LENGTH => 8192" unless(defined &MAX_COMMENT_LENGTH);
	eval "use constant MAX_LINES => 100" unless(defined &MAX_LINES);
	eval "use constant MAX_LINES_SHOWN => 15" unless(defined &MAX_LINES_SHOWN);
	eval "use constant MAX_KEY_LOG => 1000" unless(defined &MAX_KEY_LOG);

	# Captcha
	eval "use constant ENABLE_CAPTCHA => 0" unless(defined &ENABLE_CAPTCHA);
	eval "use constant CAPTCHA_HEIGHT => 18" unless(defined &CAPTCHA_HEIGHT);
	eval "use constant CAPTCHA_SCRIBBLE => 0.2" unless(defined &CAPTCHA_SCRIBBLE);
	eval "use constant CAPTCHA_SCALING => 0.15" unless(defined &CAPTCHA_SCALING);
	eval "use constant CAPTCHA_ROTATION => 0.3" unless(defined &CAPTCHA_ROTATION);
	eval "use constant CAPTCHA_SPACING => 2.5" unless(defined &CAPTCHA_SPACING);

	# Tweaks
	eval "use constant CHARSET => 'utf-8'" unless(defined &CHARSET);
	eval "use constant PROXY_CHECK => ()" unless(defined &PROXY_CHECK);
	eval "use constant TRIM_METHOD => 1" unless(defined &TRIM_METHOD);
	eval "use constant DATE_STYLE => '2ch'" unless(defined &DATE_STYLE);
	eval "use constant DISPLAY_ID => 1" unless(defined &DISPLAY_ID);
	eval "use constant EMAIL_ID => 'Heaven'" unless(defined &EMAIL_ID);
	eval "use constant SILLY_ANONYMOUS => 0" unless(defined &SILLY_ANONYMOUS);
	eval "use constant FORCED_ANON => 0" unless(defined &FORCED_ANON);
	eval "use constant TRIPKEY => '!'" unless(defined &TRIPKEY);
	eval "use constant ALTERNATE_REDIRECT => 0" unless(defined &ALTERNATE_REDIRECT);
	eval "use constant ENABLE_WAKABAMARK => 1" unless(defined &ENABLE_WAKABAMARK);
	eval "use constant APPROX_LINE_LENGTH => 150" unless(defined &APPROX_LINE_LENGTH);
	eval "use constant COOKIE_PATH => 'root'" unless(defined &COOKIE_PATH);

	# Internal paths and files - might as well leave this alone.
	eval "use constant RES_DIR => 'res/'" unless(defined &RES_DIR);
	eval "use constant HTML_SELF => 'index.html'" unless(defined &HTML_SELF);
	eval "use constant HTML_BACKLOG => 'subback.html'" unless(defined &HTML_BACKLOG);
	eval "use constant RSS_FILE => 'index.rss'" unless(defined &RSS_FILE);
	eval "use constant CSS_DIR => 'css/'" unless(defined &CSS_DIR);
	eval "use constant PAGE_EXT => '.html'" unless(defined &PAGE_EXT);
	eval "use constant SPAM_FILE => 'spam.txt'" unless(defined &SPAM_FILE);
}

1;
