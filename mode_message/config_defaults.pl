use strict;

BEGIN {
	use constant S_NOADMIN => 'No ADMIN_PASS defined in the configuration';	# Returns error when the config is incomplete
	use constant S_NOSECRET => 'No SECRET defined in the configuration';	# Returns error when the config is incomplete

	# System config
	die S_NOADMIN unless(defined &ADMIN_PASS);
	die S_NOSECRET unless(defined &SECRET);
	eval "use constant ADMIN_TRIPS => ()" unless(defined &ADMIN_TRIPS);

	# Page look
	eval "use constant TITLE => 'Kareha message board'" unless(defined &TITLE);
	eval "use constant SHOWTITLETXT => 1" unless(defined &SHOWTITLETXT);
	eval "use constant SHOWTITLEIMG => 0" unless(defined &SHOWTITLEIMG);
	eval "use constant TITLEIMG => 'title.jpg'" unless(defined &TITLEIMG);
	eval "use constant THREADS_DISPLAYED => 10" unless(defined &THREADS_DISPLAYED);
	eval "use constant THREADS_LISTED => 40" unless(defined &THREADS_LISTED);
	eval "use constant REPLIES_PER_THREAD => 10" unless(defined &REPLIES_PER_THREAD);
	eval "use constant S_ANONAME => 'Anonymous'" unless(defined &S_ANONAME);
	eval "use constant DEFAULT_STYLE => 'Headline'" unless(defined &DEFAULT_STYLE);
	eval "use constant FAVICON => 'kareha.ico'" unless(defined &FAVICON);

	# Limitations
	eval "use constant ALLOW_TEXT_THREADS => 1" unless(defined &ALLOW_TEXT_THREADS);
	eval "use constant ALLOW_TEXT_REPLIES => 1" unless(defined &ALLOW_TEXT_REPLIES);
	eval "use constant MAX_RES => 1000" unless(defined &MAX_RES);
	eval "use constant MAX_THREADS => 0" unless(defined &MAX_THREADS);
	eval "use constant MAX_POSTS => 0" unless(defined &MAX_POSTS);
	eval "use constant MAX_MEGABYTES => 0" unless(defined &MAX_MEGABYTES);
	eval "use constant MAX_FIELD_LENGTH => 100" unless(defined &MAX_FIELD_LENGTH);
	eval "use constant MAX_COMMENT_LENGTH => 8192" unless(defined &MAX_COMMENT_LENGTH);
	eval "use constant MAX_LINES => 100" unless(defined &MAX_LINES);
	eval "use constant MAX_LINES_SHOWN => 15" unless(defined &MAX_LINES_SHOWN);

	# Image posts
	eval "use constant ALLOW_IMAGE_THREADS => 0" unless(defined &ALLOW_IMAGE_THREADS);
	eval "use constant ALLOW_IMAGE_REPLIES => 0" unless(defined &ALLOW_IMAGE_REPLIES);
	eval "use constant IMAGE_REPLIES_PER_THREAD => 0" unless(defined &IMAGE_REPLIES_PER_THREAD);
	eval "use constant MAX_KB => 1000" unless(defined &MAX_KB);
	eval "use constant MAX_W => 200" unless(defined &MAX_W);
	eval "use constant MAX_H => 200" unless(defined &MAX_H);
	eval "use constant THUMBNAIL_SMALL => 1" unless(defined &THUMBNAIL_SMALL);
	eval "use constant THUMBNAIL_QUALITY => 70" unless(defined &THUMBNAIL_QUALITY);
	eval "use constant ALLOW_UNKNOWN => 0" unless(defined &ALLOW_UNKNOWN);
	eval "use constant MUNGE_UNKNOWN => '.unknown'" unless(defined &MUNGE_UNKNOWN);
	eval "use constant FORBIDDEN_EXTENSIONS => ('php','php3','php4','phtml','shtml','cgi','pl','pm','py','r','exe','dll','scr','pif','asp','cfm','jsp','vbs')" unless(defined &FORBIDDEN_EXTENSIONS);
	eval "use constant STUPID_THUMBNAILING => 0" unless(defined &STUPID_THUMBNAILING);
	eval "use constant MAX_IMAGE_WIDTH => 16384" unless(defined &MAX_IMAGE_WIDTH);
	eval "use constant MAX_IMAGE_HEIGHT => 16384" unless(defined &MAX_IMAGE_HEIGHT);
	eval "use constant MAX_IMAGE_PIXELS => 50000000" unless(defined &MAX_IMAGE_PIXELS);
	eval "use constant CONVERT_COMMAND => 'convert'" unless(defined &CONVERT_COMMAND);

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
	eval "use constant REQUIRE_THREAD_TITLE => 1" unless(defined &REQUIRE_THREAD_TITLE);
	eval "use constant DATE_STYLE => '2ch'" unless(defined &DATE_STYLE);
	eval "use constant DISPLAY_ID => 'thread board'" unless(defined &DISPLAY_ID);
	eval "use constant EMAIL_ID => 'Heaven'" unless(defined &EMAIL_ID);
	eval "use constant SILLY_ANONYMOUS => ''" unless(defined &SILLY_ANONYMOUS);
	eval "use constant FORCED_ANON => 0" unless(defined &FORCED_ANON);
	eval "use constant TRIPKEY => '!'" unless(defined &TRIPKEY);
	eval "use constant ALTERNATE_REDIRECT => 0" unless(defined &ALTERNATE_REDIRECT);
	eval "use constant ENABLE_WAKABAMARK => 1" unless(defined &ENABLE_WAKABAMARK);
	eval "use constant APPROX_LINE_LENGTH => 150" unless(defined &APPROX_LINE_LENGTH);
	eval "use constant COOKIE_PATH => 'root'" unless(defined &COOKIE_PATH);
	eval "use constant STYLE_COOKIE => 'karehastyle'" unless(defined &STYLE_COOKIE);
	eval "use constant ENABLE_DELETION => 1" unless(defined &ENABLE_DELETION);
	eval "use constant VISIBLE_ADMINS => 0" unless(defined &VISIBLE_ADMINS);
	eval "use constant PAGE_GENERATION => 'single'" unless(defined &PAGE_GENERATION);
	eval "use constant DELETE_FIRST => 'single'" unless(defined &DELETE_FIRST);
	eval "use constant FUDGE_BLOCKQUOTES => 0" unless(defined &FUDGE_BLOCKQUOTES);
	eval "use constant USE_XHTML => 1" unless(defined &USE_XHTML);

	# Internal paths and files - might as well leave this alone.
	eval "use constant RES_DIR => 'res/'" unless(defined &RES_DIR);
	eval "use constant CSS_DIR => 'css/'" unless(defined &CSS_DIR);
	eval "use constant IMG_DIR => 'src/'" unless(defined &IMG_DIR);
	eval "use constant THUMB_DIR => 'thumb/'" unless(defined &THUMB_DIR);
	eval "use constant PAGE_EXT => '.html'" unless(defined &PAGE_EXT);
	eval "use constant HTML_SELF => 'index.html'" unless(defined &HTML_SELF);
	eval "use constant HTML_BACKLOG => 'subback.html'" unless(defined &HTML_BACKLOG);
	eval "use constant RSS_FILE => 'index.rss'" unless(defined &RSS_FILE);
	eval "use constant JS_FILE => 'kareha.js'" unless(defined &JS_FILE);
	eval "use constant SPAM_FILE => 'spam.txt'" unless(defined &SPAM_FILE);

	eval "use constant FILETYPES => ()" unless(defined &FILETYPES);

	eval "use constant KAREHA_VERSION => '2.0.3'" unless(defined &KAREHA_VERSION);
}

1;