#
# Example config file.
# 
# Uncomment and edit the options you want to specifically change from the
# default values. You must specify ADMIN_PASS and SECRET.
#

# System config
#use constant ADMIN_PASS => 'CHANGEME';		# Admin password. For fucks's sake, change this.
#use constant SECRET => 'CHANGEME';			# Cryptographic secret. CHANGE THIS to something totally random, and long.
#use constant ADMIN_TRIPS => ('!!example1','!!example2');	# Admin tripcodes, for startng threads when locked down, and similar.

# Page look
#use constant TITLE => 'Kareha message board';	# Name of this image board
#use constant THREADS_DISPLAYED => 10;			# Number of threads on the front page
#use constant THREADS_LISTED => 40;				# Number of threads in the thread list
#use constant REPLIES_PER_THREAD => 10;			# Replies shown
#use constant S_ANONAME => 'Anonymous';			# Defines what to print if there is no text entered in the name field
#use constant DEFAULT_STYLE => 'Headline';		# Default CSS style title

# Limitations
#use constant ALLOW_TEXT_THREADS => 1;		# Allow users to create text threads
#use constant ALLOW_TEXT_REPLIES => 1;		# Allow users to make text replies
#use constant ALLOW_IMAGE_THREADS => 0;		# Allow users to create image threads
#use constant ALLOW_IMAGE_REPLIES => 0;		# Allow users to make image replies
#use constant MAX_RES => 1000;				# Maximum topic bumps
#use constant MAX_THREADS => 500;			# Maximum number of threads - set to 0 to disable thread deletion
#use constant MAX_FIELD_LENGTH => 100;		# Maximum number of characters in subject, name, and email
#use constant MAX_COMMENT_LENGTH => 8192;	# Maximum number of characters in a comment
#use constant MAX_LINES => 100;				# Max lines per post (0 = no limit)
#use constant MAX_LINES_SHOWN => 15;		# Max lines of a comment shown on the main page (0 = no limit)
#use constant MAX_KEY_LOG => 1000;			# Number of captcha keys to log

# Captcha
#use constant ENABLE_CAPTCHA => 0;				# Enable verification codes (0: disabled, 1: enabled)
#use constant CAPTCHA_HEIGHT => 18;				# Approximate height of captcha image
#use constant CAPTCHA_SCRIBBLE => 0.2;			# Scribbling factor
#use constant CAPTCHA_SCALING => 0.15;			# Randomized scaling factor
#use constant CAPTCHA_ROTATION => 0.3;			# Randomized rotation factor
#use constant CAPTCHA_SPACING => 2.5;			# Letter spacing

# Tweaks
#use constant CHARSET => 'utf-8';				# Character set to use, typically "utf-8" or "shift_jis". Remember to set Apache to use the same character set for .html files! (AddCharset shift_jis html)
#use constant PROXY_CHECK => ();				# Ports to scan for proxies - NOT IMPLEMENTED.
#use constant TRIM_METHOD => 1;					# Which threads to trim (0: oldest - like futaba 1: least active - furthest back)
#use constant REQUIRE_THREAD_TITLE => 1;		# Require a title for threads (0: no, 1: yes)
#use constant DATE_STYLE => '2ch';				# Date style ('2ch', 'localtime, 'http')
#use constant DISPLAY_ID => 1;					# Display user IDs (0: never, 1: if no email, 2:always)
#use constant EMAIL_ID => 'Heaven';				# ID string to use when DISPLAY_ID is 1 and the user uses an email.
#use constant SILLY_ANONYMOUS => 0;				# Make up silly names for anonymous people (0: please don't, 1: based on IP, 2: based on IP and date)
#use constant FORCED_ANON => 0;					# Force anonymous posting (0: no, 1: yes)
#use constant TRIPKEY => '!';					# This character is displayed before tripcodes
#use constant ALTERNATE_REDIRECT => 0;			# Use alternate redirect method. (Javascript/meta-refresh instead of HTTP forwards.)
#use constant ENABLE_WAKABAMARK => 1;			# Enable WakabaMark formatting. (0: no, 1: yes)
#use constant APPROX_LINE_LENGTH => 150;		# Approximate line length used by reply abbreviation code to guess at the length of a reply.
#use constant COOKIE_PATH => 'root';			# Path argument for cookies ('root': cookies apply to all boards on the site, 'current': cookies apply only to this board, 'parent': cookies apply to all boards in the parent directory) - does NOT apply to the style cookie!
#use constant STYLE_COOKIE => 'karehastyle';	# Cookie name for the style selector.
#use constant ENABLE_DELETION => 1;				# Enable user deletion of posts. (0: no, 1: yes)

# Internal paths and files - might as well leave this alone.
#use constant RES_DIR => 'res/';				# Reply cache directory (needs to be writeable by the script)
#use constant HTML_SELF => 'index.html';		# Name of main html file
#use constant HTML_BACKLOG => 'subback.html';	# Name of backlog html file
#use constant RSS_FILE => 'index.rss';			# RSS file. Set to '' to disable RSS support.
#use constant CSS_DIR => 'css/';				# CSS file directory
#use constant PAGE_EXT => '.html';				# Extension used for board pages after first
#use constant SPAM_FILE => 'spam.txt';			# Spam definitions. Hint: set all boards to use the same file for easy updating.

1;
