# System config
#use constant ADMIN_PASS => 'CHANGEME';		# Admin password. For fucks's sake, change this.
#use constant SECRET => 'CHANGEME';			# Cryptographic secret. CHANGE THIS to something totally random, and long.

# Page look
#use constant TITLE => 'Kareha message board';	# Name of this image board
#use constant THREADS_DISPLAYED => 10;			# Number of threads on the front page
#use constant THREADS_LISTED => 40;				# Number of threads in the thread list
#use constant REPLIES_PER_THREAD => 10;			# Replies shown
#use constant S_ANONAME => 'Anonymous';			# Defines what to print if there is no text entered in the name field
#use constant DEFAULT_STYLE => 'Headline';		# Default CSS style title

# Limitations
#use constant MAX_RES => 1000;				# Maximum topic bumps
#use constant MAX_THREADS => 500;			# Maximum number of threads - set to 0 to disable thread deletion
#use constant MAX_FIELD_LENGTH => 100;		# Maximum number of characters in subject, name, and email
#use constant MAX_COMMENT_LENGTH => 8192;	# Maximum number of characters in a comment
#use constant MAX_LINES => 100;				# Max lines per post (0 = no limit)
#use constant MAX_LINES_SHOWN => 15;		# Max lines of a comment shown on the main page (0 = no limit)
#use constant MAX_KEY_LOG => 1000;			# Number of captcha keys to log

# Captcha
#use constant ENABLE_CAPTCHA => 0;			# Enable verification codes (0: disabled, 1: enabled)

# Tweaks
#use constant CHARSET => 'utf-8';			# Character set to use, typically "utf-8" or "shift_jis". Remember to set Apache to use the same character set for .html files! (AddCharset shift_jis html)
#use constant PROXY_CHECK => ();			# Ports to scan for proxies - NOT IMPLEMENTED.
#use constant TRIM_METHOD => 1;				# Which threads to trim (0: oldest - like futaba 1: least active - furthest back)
#use constant DATE_STYLE => 0;				# Date style (0: 2ch-style 1: localtime)
#use constant DISPLAY_ID => 1;				# Display user IDs (0: never, 1: if no email, 2:always)
#use constant SECURE_ID => 1;				# Use secure IDs instead of 2ch-style IDs.
#use constant EMAIL_ID => 'Heaven';			# ID string to use when DISPLAY_ID is 1 and the user uses an email.
#use constant SILLY_ANONYMOUS => 0;			# Make up silly names for anonymous people (0: please don't, 1: based on IP, 2: based on IP and date)
#use constant FORCED_ANON => 0;				# Force anonymous posting (0: no, 1: yes)
#use constant TRIPKEY => '!';				# This character is displayed before tripcodes
#use constant ALTERNATE_REDIRECT => 0;		# Use alternate redirect method. (Javascript/meta-refresh instead of HTTP forwards.)
#use constant ENABLE_WAKABAMARK => 1;		# Enable WakabaMark formatting. (0: no, 1: yes)
#use constant APPROX_LINE_LENGTH => 150;	# Approximate line length used by reply abbreviation code to guess at the length of a reply.

# Internal paths and files - might as well leave this alone.
#use constant RES_DIR => 'res/';				# Reply cache directory (needs to be writeable by the script)
#use constant HTML_SELF => 'index.html';		# Name of main html file
#use constant HTML_BACKLOG => 'subback.html';	# Name of backlog html file
#use constant RSS_FILE => 'index.rss';			# RSS file. Set to '' to disable RSS support.
#use constant CSS_DIR => 'css/';				# CSS file directory
#use constant PAGE_EXT => '.html';				# Extension used for board pages after first

1;
