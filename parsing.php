<?php
// Valid constant names
define("WIRELESS", false);

// Parse bulletin board code in a string, as well as smileys optionally.
function parse_bbc($message, $smileys = true, $cache_id = '', $local_disable = array())
{
	global $txt, $scripturl, $context, $modSettings, $user_info;
	static $bbc_codes = array(), $itemcodes = array(), $no_autolink_tags = array();
	$context['browser']['is_gecko'] = false;
	$context['browser']['is_ie5'] = false;
	$context['browser']['is_ie5'] = false;
	$context['browser']['is_ie4'] = false;
	$context['browser']['is_mac_ie'] = false;
	$context['browser']['is_konqueror'] = false;
	$context['browser']['is_opera'] = false;
	$context['browser']['is_ie'] = false;
	$disabled = array();
	
	//theymos - die if it's taking way too long
	if(isset($_SERVER["REQUEST_TIME_FLOAT"]) && microtime(true) - $_SERVER["REQUEST_TIME_FLOAT"] > 29 && strlen($message)>500 && php_sapi_name() != 'cli') {
		die();
	}

	// Never show smileys for wireless clients.  More bytes, can't see it anyway :P.
	if (WIRELESS)
		$smileys = false;
	elseif ($smileys !== null && ($smileys == '1' || $smileys == '0'))
		$smileys = (bool) $smileys;

	ECHO "a";
	// if (empty($modSettings['enableBBC']) && $message !== false)
	// {
	// 	if ($smileys === true)
	// 		parsesmileys($message);
	// ECHO "b";

	// 	return $message;
	// }
	ECHO "c";

	// Just in case it wasn't determined yet whether UTF-8 is enabled.
	if (!isset($context['utf8']))
		// $context['utf8'] = (empty(ç['global_character_set']) ? $txt['lang_character_set'] : $modSettings['global_character_set']) === 'UTF-8';
		$context['utf8'] = true;

	//theymos - disable links and images on pages where we don't want to send a referer to random people
	$disabledsecurity='';
	if(isset($_GET['sesc'])) {
		$cache_id = '';
		$disabled['img']=true;
		$disabled['iurl']=true;
		$disabled['url']=true;
		$disabled['ftp']=true;
		$disabledsecurity=' (FORUM: disabled on this page for security.)';
	}
	if(isset($_GET['patrol'])) {
		$cache_id = '';
		$disabled['black']=true;
		$disabled['color']=true;
	}

	//theymos - these tags are aways disabled
	$disabled['flash'] = true;
	$disabled['move'] = true;

	// Sift out the bbc for a performance improvement.
	if (empty($bbc_codes) || $message === false)
	{
		/*if (!empty($modSettings['disabledBBC']))
		{
			$temp = explode(',', strtolower($modSettings['disabledBBC']));

			foreach ($temp as $tag)
				$disabled[trim($tag)] = true;
		}

		if (empty($modSettings['enableEmbeddedFlash']))
			$disabled['flash'] = true;*/

		/* The following bbc are formatted as an array, with keys as follows:

			tag: the tag's name - should be lowercase!

			type: one of...
				- (missing): [tag]parsed content[/tag]
				- unparsed_equals: [tag=xyz]parsed content[/tag]
				- parsed_equals: [tag=parsed data]parsed content[/tag]
				- unparsed_content: [tag]unparsed content[/tag]
				- closed: [tag], [tag/], [tag /]
				- unparsed_commas: [tag=1,2,3]parsed content[/tag]
				- unparsed_commas_content: [tag=1,2,3]unparsed content[/tag]
				- unparsed_equals_content: [tag=...]unparsed content[/tag]

			parameters: an optional array of parameters, for the form
			  [tag abc=123]content[/tag].  The array is an associative array
			  where the keys are the parameter names, and the values are an
			  array which may contain the following:
				- match: a regular expression to validate and match the value.
				- quoted: true if the value should be quoted.
				- validate: callback to evaluate on the data, which is $data.
				- value: a string in which to replace $1 with the data.
				  either it or validate may be used, not both.
				- optional: true if the parameter is optional.

			test: a regular expression to test immediately after the tag's
			  '=', ' ' or ']'.  Typically, should have a \] at the end.
			  Optional.

			content: only available for unparsed_content, closed,
			  unparsed_commas_content, and unparsed_equals_content.
			  $1 is replaced with the content of  the tag.  Parameters
			  are repalced in the form {param}.  For unparsed_commas_content,
			  $2, $3, ..., $n are replaced.

			before: only when content is not used, to go before any
			  content.  For unparsed_equals, $1 is replaced with the value.
			  For unparsed_commas, $1, $2, ..., $n are replaced.

			after: similar to before in every way, except that it is used
			  when the tag is closed.

			disabled_content: used in place of content when the tag is
			  disabled.  For closed, default is '', otherwise it is '$1' if
			  block_level is false, '<div>$1</div>' elsewise.

			disabled_before: used in place of before when disabled.  Defaults
			  to '<div>' if block_level, '' if not.

			disabled_after: used in place of after when disabled.  Defaults
			  to '</div>' if block_level, '' if not.

			block_level: set to true the tag is a "block level" tag, similar
			  to HTML.  Block level tags cannot be nested inside tags that are
			  not block level, and will not be implicitly closed as easily.
			  One break following a block level tag may also be removed.

			trim: if set, and 'inside' whitespace after the begin tag will be
			  removed.  If set to 'outside', whitespace after the end tag will
			  meet the same fate.

			validate: except when type is missing or 'closed', a callback to
			  validate the data as $data.  Depending on the tag's type, $data
			  may be a string or an array of strings (corresponding to the
			  replacement.)

			quoted: when type is 'unparsed_equals' or 'parsed_equals' only,
			  may be not set, 'optional', or 'required' corresponding to if
			  the content may be quoted.  This allows the parser to read
			  [tag="abc]def[esdf]"] properly.

			require_parents: an array of tag names, or not set.  If set, the
			  enclosing tag *must* be one of the listed tags, or parsing won't
			  occur.

			require_children: similar to require_parents, if set children
			  won't be parsed if they are not in the list.

			disallow_children: similar to, but very different from,
			  require_children, if it is set the listed tags will not be
			  parsed inside the tag.
		*/

		$codes = array(
			array(
				'tag' => 'abbr',
				'type' => 'unparsed_equals',
				'before' => '<abbr title="$1">',
				'after' => '</abbr>',
				'quoted' => 'optional',
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'acronym',
				'type' => 'unparsed_equals',
				'before' => '<acronym title="$1">',
				'after' => '</acronym>',
				'quoted' => 'optional',
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'anchor',
				'type' => 'unparsed_equals',
				'test' => '[#]?([A-Za-z][A-Za-z0-9_\-]*)\]',
				'before' => '<span id="post_$1" />',
				'after' => '',
			),
			array(
				'tag' => 'b',
				'before' => '<b>',
				'after' => '</b>',
			),
			array(
				'tag' => 'black',
				'before' => '<span style="color: black;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'blue',
				'before' => '<span style="color: blue;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'br',
				'type' => 'closed',
				'content' => '<br />',
			),
			array(
				'tag' => 'btc',
				'type' => 'closed',
				'content' => '<span class="BTC">BTC</span>',
			),
			array(
				'tag' => 'code',
				'type' => 'unparsed_content',
				'content' => '<div class="codeheader">' . '$txt[\'smf238\']' . ':</div><div class="code">' . ($context['browser']['is_gecko'] ? '<pre style="margin-top: 0; display: inline;">$1</pre>' : '$1') . '</div>',
				// !!! Maybe this can be simplified?
				'validate' => isset($disabled['code']) ? null : function(&$tag, &$data, $disabled) {
					global $context;

					if (!isset($disabled['code']))
					{
						$php_parts = preg_split('~(&lt;\?php|\?&gt;)~', $data, -1, PREG_SPLIT_DELIM_CAPTURE);

						for ($php_i = 0, $php_n = count($php_parts); $php_i < $php_n; $php_i++)
						{
							// Do PHP code coloring?
							if ($php_parts[$php_i] != '&lt;?php')
								continue;

							$php_string = '';
							while ($php_i + 1 < count($php_parts) && $php_parts[$php_i] != '?&gt;')
							{
								$php_string .= $php_parts[$php_i];
								$php_parts[$php_i++] = '';
							}
							$php_parts[$php_i] = highlight_php_code($php_string . $php_parts[$php_i]);
						}

						// Fix the PHP code stuff...
						$data = str_replace("<pre style=\"display: inline;\">\t</pre>", "\t", implode('', $php_parts));

						// Older browsers are annoying, aren't they?
						if ($context['browser']['is_ie4'] || $context['browser']['is_ie5'] || $context['browser']['is_ie5.5'])
							$data = str_replace("\t", "<pre style=\"display: inline;\">\t</pre>", $data);
						elseif (!$context['browser']['is_gecko'])
							$data = str_replace("\t", "<span style=\"white-space: pre;\">\t</span>", $data);
					}},
				'block_level' => true,
			),
			array(
				'tag' => 'code',
				'type' => 'unparsed_equals_content',
				'content' => '<div class="codeheader">' . '$txt[\'smf238\']' . ': ($2)</div><div class="code">' . ($context['browser']['is_gecko'] ? '<pre style="margin-top: 0; display: inline;">$1</pre>' : '$1') . '</div>',
				// !!! Maybe this can be simplified?
				'validate' => isset($disabled['code']) ? null : function(&$tag, &$data, $disabled) {
					global $context;

					if (!isset($disabled['code']))
					{
						$php_parts = preg_split('~(&lt;\?php|\?&gt;)~', $data[0], -1, PREG_SPLIT_DELIM_CAPTURE);

						for ($php_i = 0, $php_n = count($php_parts); $php_i < $php_n; $php_i++)
						{
							// Do PHP code coloring?
							if ($php_parts[$php_i] != '&lt;?php')
								continue;

							$php_string = '';
							while ($php_i + 1 < count($php_parts) && $php_parts[$php_i] != '?&gt;')
							{
								$php_string .= $php_parts[$php_i];
								$php_parts[$php_i++] = '';
							}
							$php_parts[$php_i] = highlight_php_code($php_string . $php_parts[$php_i]);
						}

						// Fix the PHP code stuff...
						$data[0] = str_replace("<pre style=\"display: inline;\">\t</pre>", "\t", implode('', $php_parts));

						// Older browsers are annoying, aren't they?
						if ($context['browser']['is_ie4'] || $context['browser']['is_ie5'] || $context['browser']['is_ie5.5'])
							$data = str_replace("\t", "<pre style=\"display: inline;\">\t</pre>", $data);
						elseif (!$context['browser']['is_gecko'])
							$data = str_replace("\t", "<span style=\"white-space: pre;\">\t</span>", $data);
					}},
				'block_level' => true,
			),
			array(
				'tag' => 'center',
				'before' => '<div align="center">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'color',
				'type' => 'unparsed_equals',
				'test' => '(#[\da-fA-F]{3}|#[\da-fA-F]{6}|[A-Za-z]{1,12})\]',
				'before' => '<span style="color: $1;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'email',
				'type' => 'unparsed_content',
				'content' => '<a href="mailto:$1">$1</a>',
				// !!! Should this respect guest_hideContacts?
				'validate' => function(&$tag, &$data, $disabled) {$data = strtr($data, array('<br />' => ''));},
			),
			array(
				'tag' => 'email',
				'type' => 'unparsed_equals',
				'before' => '<a href="mailto:$1">',
				'after' => '</a>',
				// !!! Should this respect guest_hideContacts?
				'disallow_children' => array('email', 'ftp', 'url', 'iurl'),
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'ftp',
				'type' => 'unparsed_content',
				'content' => '<a href="$1">$1</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					$data = strtr($data, array('<br />' => ''));
					if (strpos($data, 'ftp://') !== 0 && strpos($data, 'ftps://') !== 0)
						$data = 'ftp://' . $data;
				},
			),
			array(
				'tag' => 'ftp',
				'type' => 'unparsed_equals',
				'before' => '<a href="$1">',
				'after' => '</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					if (strpos($data, 'ftp://') !== 0 && strpos($data, 'ftps://') !== 0)
						$data = 'ftp://' . $data;
				},
				'disallow_children' => array('email', 'ftp', 'url', 'iurl'),
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'font',
				'type' => 'unparsed_equals',
				'test' => '[A-Za-z0-9_,\-\s]+?\]',
				'before' => '<span style="font-family: $1;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'flash',
				'type' => 'unparsed_commas_content',
				'test' => '\d+,\d+\]',
				'content' => ($context['browser']['is_ie'] && !$context['browser']['is_mac_ie'] ? '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="$2" height="$3"><param name="movie" value="$1" /><param name="play" value="true" /><param name="loop" value="true" /><param name="quality" value="high" /><param name="AllowScriptAccess" value="never" /><embed src="$1" width="$2" height="$3" play="true" loop="true" quality="high" AllowScriptAccess="never" /><noembed><a href="$1">$1</a></noembed></object>' : '<embed type="application/x-shockwave-flash" src="$1" width="$2" height="$3" play="true" loop="true" quality="high" AllowScriptAccess="never" /><noembed><a href="$1">$1</a></noembed>'),
				'validate' => function(&$tag, &$data, $disabled) {
					if (isset($disabled['url']))
						$tag['content'] = '$1';
					elseif (strpos($data[0], 'http://') !== 0 && strpos($data[0], 'https://') !== 0)
						$data[0] = 'http://' . $data[0];
				},
				'disabled_content' => $disabledsecurity ? '$1': '<a href="$1">$1</a>',
			),
			array(
				'tag' => 'green',
				'before' => '<span style="color: green;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'glow',
				'type' => 'unparsed_commas',
				'test' => '[#0-9a-zA-Z\-]{3,12},([012]\d{1,2}|\d{1,2})(,[^]]+)?\]',
				'before' => $context['browser']['is_ie'] ? '<table border="0" cellpadding="0" cellspacing="0" style="display: inline; vertical-align: middle; font: inherit;"><tr><td style="filter: Glow(color=$1, strength=$2); font: inherit;">' : '<span style="background-color: $1;">',
				'after' => $context['browser']['is_ie'] ? '</td></tr></table> ' : '</span>',
			),
			array(
				'tag' => 'hr',
				'type' => 'closed',
				'content' => '<hr />',
				'block_level' => true,
			),
			array(
				'tag' => 'html',
				'type' => 'unparsed_content',
				'content' => '$1',
				'block_level' => true,
				'disabled_content' => '$1',
			),
			array(
				'tag' => 'img',
				'type' => 'unparsed_content',
				'parameters' => array(
					'alt' => array('optional' => true),
					'width' => array('optional' => true, 'value' => ' width="$1"', 'match' => '(\d{1,4})'),
					'height' => array('optional' => true, 'value' => ' height="$1"', 'match' => '(\d{1,4})'),
				),
				'content' => '<img class="userimg" src="$1" alt="{alt}"{width}{height} border="0" />',
				'validate' => function(&$tag, &$data, $disabled) {
					$data = strtr($data, array('<br />' => ''));
					if (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0)
						$data = 'http://' . $data;
					if(!isset($disabled['img']))
						$data = proxyurl($data);
				},
				'disabled_content' => $disabledsecurity ? ('($1)'.$disabledsecurity) : '<a href="$1">$1</a>',
			),
			array(
				'tag' => 'img',
				'type' => 'unparsed_content',
				'content' => '<img class="userimg" src="$1" alt="" border="0" />',
				'validate' => function(&$tag, &$data, $disabled) {
					$data = strtr($data, array('<br />' => ''));
					if (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0)
						$data = 'http://' . $data;
					if(!isset($disabled['img']))
						$data = proxyurl($data);
				},
				'disabled_content' => $disabledsecurity ? ('($1)'.$disabledsecurity) : '<a href="$1">$1</a>',
			),
			array(
				'tag' => 'i',
				'before' => '<i>',
				'after' => '</i>',
			),
			array(
				'tag' => 'iurl',
				'type' => 'unparsed_content',
				'content' => '<a class="ul" href="$1">$1</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					$data = strtr($data, array('<br />' => ''));
					if (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0 && strpos($data, 'bitcoin:') !== 0 && strpos($data, 'magnet:') !== 0)
						$data = 'http://' . $data;
				},
			),
			array(
				'tag' => 'iurl',
				'type' => 'unparsed_equals',
				'before' => '<a class="ul" href="$1">',
				'after' => '</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					if (substr($data, 0, 1) == '#')
						$data = '#post_' . substr($data, 1);
					elseif (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0 && strpos($data, 'bitcoin:') !== 0 && strpos($data, 'magnet:') !== 0)
						$data = 'http://' . $data;
				},
				'disallow_children' => array('email', 'ftp', 'url', 'iurl'),
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'li',
				'before' => '<li>',
				'after' => '</li>',
				'trim' => 'outside',
				'require_parents' => array('list'),
				'block_level' => true,
				'disabled_before' => '',
				'disabled_after' => '<br />',
			),
			array(
				'tag' => 'list',
				'before' => '<ul style="margin-top: 0; margin-bottom: 0;">',
				'after' => '</ul>',
				'trim' => 'inside',
				'require_children' => array('li'),
				'block_level' => true,
			),
			array(
				'tag' => 'list',
				'parameters' => array(
					'type' => array('match' => '(none|disc|circle|square|decimal|decimal-leading-zero|lower-roman|upper-roman|lower-alpha|upper-alpha|lower-greek|lower-latin|upper-latin|hebrew|armenian|georgian|cjk-ideographic|hiragana|katakana|hiragana-iroha|katakana-iroha)'),
				),
				'before' => '<ul style="margin-top: 0; margin-bottom: 0; list-style-type: {type};">',
				'after' => '</ul>',
				'trim' => 'inside',
				'require_children' => array('li'),
				'block_level' => true,
			),
			array(
				'tag' => 'left',
				'before' => '<div style="text-align: left;">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'ltr',
				'before' => '<div dir="ltr">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'me',
				'type' => 'unparsed_equals',
				'before' => '<div class="meaction">* $1 ',
				'after' => '</div>',
				'quoted' => 'optional',
				'block_level' => true,
				'disabled_before' => '/me ',
				'disabled_after' => '<br />',
			),
			array(
				'tag' => 'move',
				'before' => '<marquee>',
				'after' => '</marquee>',
				'block_level' => true,
			),
			array(
				'tag' => 'nbsp',
				'type' => 'closed',
				'content' => '&nbsp;',
			),
			array(
				'tag' => 'nobbc',
				'type' => 'unparsed_content',
				'content' => '$1',
			),
			array(
				'tag' => 'pre',
				'before' => '<pre>',
				'after' => '</pre>',
			),
			array(
				'tag' => 'php',
				'type' => 'unparsed_content',
				'content' => '<div class="phpcode">$1</div>',
				'validate' => isset($disabled['php']) ? null : function(&$tag, &$data, $disabled) {
					if (!isset($disabled['php']))
					{
						$add_begin = substr(trim($data), 0, 5) != '&lt;?';
						$data = highlight_php_code($add_begin ? '&lt;?php ' . $data . '?&gt;' : $data);
						if ($add_begin)
							$data = preg_replace(array('~^(.+?)&lt;\?.{0,40}?php(&nbsp;|\s)~', '~\?&gt;((?:</(font|span)>)*)$~'), '$1', $data, 2);
					}},
				'block_level' => true,
				'disabled_content' => '$1',
			),
			array(
				'tag' => 'quote',
				'before' => '<div class="quoteheader">' . '$txt[\'smf240\']' . '</div><div class="quote">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'quote',
				'parameters' => array(
					'author' => array('match' => '(.{1,192}?)', 'quoted' => true, 'validate' => 'parse_bbc'),
				),
				'before' => '<div class="quoteheader">' . '$txt[\'smf239\']' . ': {author}</div><div class="quote">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'quote',
				'type' => 'parsed_equals',
				'before' => '<div class="quoteheader">' . '$txt[\'smf239\']' . ': $1</div><div class="quote">',
				'after' => '</div>',
				'quoted' => 'optional',
				'block_level' => true,
			),
			array(
				'tag' => 'quote',
				'parameters' => array(
					'author' => array('match' => '([^<>]{1,192}?)'),
					'link' => array('match' => '(?:board=\d+;)?((?:topic|threadid)=[\dmsg#\./]{1,40}(?:;start=[\dmsg#\./]{1,40})?|action=profile;u=\d+)'),
					'date' => array('match' => '(\d+)', 'validate' => 'timeformat'),
				),
				'before' => '<div class="quoteheader"><a href="' . $scripturl . '?{link}">' . '$txt[\'smf239\']' . ': {author} ' . '$txt[\'176\']' . ' {date}</a></div><div class="quote">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'quote',
				'parameters' => array(
					'author' => array('match' => '(.{1,192}?)', 'validate' => 'parse_bbc'),
				),
				'before' => '<div class="quoteheader">' . '$txt[\'smf239\']' . ': {author}</div><div class="quote">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'right',
				'before' => '<div style="text-align: right;">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 'red',
				'before' => '<span style="color: red;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'rtl',
				'before' => '<div dir="rtl">',
				'after' => '</div>',
				'block_level' => true,
			),
			array(
				'tag' => 's',
				'before' => '<del>',
				'after' => '</del>',
			),
			array(
				'tag' => 'size',
				'type' => 'unparsed_equals',
				'test' => '([1-9][\d]?p[xt]|(?:x-)?small(?:er)?|(?:x-)?large[r]?)\]',
				// !!! line-height
				'before' => '<span style="font-size: $1 !important; line-height: 1.3em;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'size',
				'type' => 'unparsed_equals',
				'test' => '[1-9]\]',
				// !!! line-height
				'before' => '<font size="$1" style="line-height: 1.3em;">',
				'after' => '</font>',
			),
			array(
				'tag' => 'sub',
				'before' => '<sub>',
				'after' => '</sub>',
			),
			array(
				'tag' => 'sup',
				'before' => '<sup>',
				'after' => '</sup>',
			),
			array(
				'tag' => 'shadow',
				'type' => 'unparsed_commas',
				'test' => '[#0-9a-zA-Z\-]{3,12},(left|right|top|bottom|[0123]\d{0,2})\]',
				'before' => $context['browser']['is_ie'] ? '<span style="filter: Shadow(color=$1, direction=$2); height: 1.2em;\">' : '<span style="text-shadow: $1 $2">',
				'after' => '</span>',
				'validate' => $context['browser']['is_ie'] ? function(&$tag, &$data, $disabled) {
					if ($data[1] == 'left')
						$data[1] = 270;
					elseif ($data[1] == 'right')
						$data[1] = 90;
					elseif ($data[1] == 'top')
						$data[1] = 0;
					elseif ($data[1] == 'bottom')
						$data[1] = 180;
					else
						$data[1] = (int) $data[1];} : function(&$tag, &$data, $disabled) {
					if ($data[1] == 'top' || (is_numeric($data[1]) && $data[1] < 50))
						return '0 -2px';
					elseif ($data[1] == 'right' || (is_numeric($data[1]) && $data[1] < 100))
						return '2px 0';
					elseif ($data[1] == 'bottom' || (is_numeric($data[1]) && $data[1] < 190))
						return '0 2px';
					elseif ($data[1] == 'left' || (is_numeric($data[1]) && $data[1] < 280))
						return '-2px 0';
					else
						return '0 0';},
			),
			array(
				'tag' => 'time',
				'type' => 'unparsed_content',
				'content' => '$1',
				'validate' => function(&$tag, &$data, $disabled) {
					if (is_numeric($data))
						$data = timeformat($data);
					else
						$tag['content'] = '[time]$1[/time]';},
			),
			array(
				'tag' => 'tt',
				'before' => '<tt>',
				'after' => '</tt>',
			),
			array(
				'tag' => 'table',
				'before' => '<table style="font: inherit; color: inherit;">',
				'after' => '</table>',
				'trim' => 'inside',
				'require_children' => array('tr'),
				'block_level' => true,
			),
			array(
				'tag' => 'tr',
				'before' => '<tr>',
				'after' => '</tr>',
				'require_parents' => array('table'),
				'require_children' => array('td'),
				'trim' => 'both',
				'block_level' => true,
				'disabled_before' => '',
				'disabled_after' => '',
			),
			array(
				'tag' => 'td',
				'before' => '<td valign="top" style="font: inherit; color: inherit;">',
				'after' => '</td>',
				'require_parents' => array('tr'),
				'trim' => 'outside',
				'block_level' => true,
				'disabled_before' => '',
				'disabled_after' => '',
			),
			array(
				'tag' => 'url',
				'type' => 'unparsed_content',
				'content' => '<a class="ul" href="$1">$1</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					$data = strtr($data, array('<br />' => ''));
					if (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0 && strpos($data, 'bitcoin:') !== 0 && strpos($data, 'magnet:') !== 0)
						$data = 'http://' . $data;
				},
			),
			array(
				'tag' => 'url',
				'type' => 'unparsed_equals',
				'before' => '<a class="ul" href="$1">',
				'after' => '</a>',
				'validate' => function(&$tag, &$data, $disabled) {
					if (strpos($data, 'http://') !== 0 && strpos($data, 'https://') !== 0 && strpos($data, 'bitcoin:') !== 0 && strpos($data, 'magnet:') !== 0)
						$data = 'http://' . $data;
				},
				'disallow_children' => array('email', 'ftp', 'url', 'iurl'),
				'disabled_after' => ' ($1)',
			),
			array(
				'tag' => 'u',
				'before' => '<span style="text-decoration: underline;">',
				'after' => '</span>',
			),
			array(
				'tag' => 'white',
				'before' => '<span style="color: white;">',
				'after' => '</span>',
			),
		);

		// This is mainly for the bbc manager, so it's easy to add tags above.  Custom BBC should be added above this line.
		if ($message === false)
			return $codes;

		// So the parser won't skip them.
		$itemcodes = array(
			'*' => '',
			'@' => 'disc',
			'+' => 'square',
			'x' => 'square',
			'#' => 'square',
			'o' => 'circle',
			'O' => 'circle',
			'0' => 'circle',
		);
		if (!isset($disabled['li']) && !isset($disabled['list']))
		{
			foreach ($itemcodes as $c => $dummy)
				$bbc_codes[$c] = array();
		}

		// Inside these tags autolink is not recommendable.
		$no_autolink_tags = array(
			'url',
			'iurl',
			'ftp',
			'email',
		);

		// Shhhh!
		if (!isset($disabled['color']))
		{
			$codes[] = array(
				'tag' => 'chrissy',
				'before' => '<span style="color: #CC0099;">',
				'after' => ' :-*</span>',
			);
			$codes[] = array(
				'tag' => 'kissy',
				'before' => '<span style="color: #CC0099;">',
				'after' => ' :-*</span>',
			);
		}

		foreach ($codes as $c)
			$bbc_codes[substr($c['tag'], 0, 1)][] = $c;
		$codes = null;
	}

	// Shall we take the time to cache this?
	if ($cache_id != '' && !empty($modSettings['cache_enable']) && (($modSettings['cache_enable'] >= 2 && strlen($message) > 1000) || strlen($message) > 2400))
	{
		// It's likely this will change if the message is modified.
		$cache_key = 'parse:' . $cache_id . '-' . md5(md5($message) . '-' . $smileys . (empty($disabled) ? '' : implode(',', array_keys($disabled))) . safe_serialize($context['browser']) . $txt['lang_locale'] . $user_info['time_offset'] . $user_info['time_format']);

		if (($temp = cache_get_data($cache_key, 600)) != null)
			return $temp;

		$cache_t = microtime();
	}

	if ($smileys === 'print')
	{
		// [glow], [shadow], and [move] can't really be printed.
		$disabled['glow'] = true;
		$disabled['shadow'] = true;
		$disabled['move'] = true;

		// Colors can't well be displayed... supposed to be black and white.
		$disabled['color'] = true;
		$disabled['black'] = true;
		$disabled['blue'] = true;
		$disabled['white'] = true;
		$disabled['red'] = true;
		$disabled['green'] = true;
		$disabled['me'] = true;

		// Color coding doesn't make sense.
		$disabled['php'] = true;

		// Links are useless on paper... just show the link.
		$disabled['ftp'] = true;
		$disabled['url'] = true;
		$disabled['iurl'] = true;
		$disabled['email'] = true;
		$disabled['flash'] = true;

		// !!! Change maybe?
		if (!isset($_GET['images']))
			$disabled['img'] = true;

		// !!! Interface/setting to add more?
	}

	if($local_disable)
		foreach($local_disable as $d)
			$disabled[$d] = true;

	$open_tags = array();
	$message = strtr($message, array("\n" => '<br />'));

	// The non-breaking-space looks a bit different each time.
	$context['server']['complex_preg_chars'] = true;
	$non_breaking_space = $context['utf8'] ? ($context['server']['complex_preg_chars'] ? '\x{C2A0}' : chr(0xC2) . chr(0xA0)) : '\xA0';

	$pos = -1;
	while ($pos !== false)
	{
		// theymos - prevent various infinite loops
		if($pos>90000) {
			if(!isset($loopcount))
				$loopcount=0;
			$loopcount++;
			if($loopcount > 500)
				return 'INVALID BBCODE: loop, probably unclosed tags';
		}

		$last_pos = isset($last_pos) ? max($pos, $last_pos) : $pos;
		$pos = strpos($message, '[', $pos + 1);

		// Failsafe.
		if ($pos === false || $last_pos > $pos)
			$pos = strlen($message) + 1;

		// Can't have a one letter smiley, URL, or email! (sorry.)
		if ($last_pos < $pos - 1)
		{
			// We want to eat one less, and one more, character (for smileys.)
			$last_pos = max($last_pos - 1, 0);
			$data = substr($message, $last_pos, $pos - $last_pos + 1);

			// Take care of some HTML!
			if (!empty($modSettings['enablePostHTML']) && strpos($data, '&lt;') !== false)
			{
				$data = preg_replace('~&lt;a\s+href=((?:&quot;)?)((?:https?://|ftps?://|mailto:|bitcoin:)\S+?)\\1&gt;~i', '[url=$2]', $data);
				$data = preg_replace('~&lt;/a&gt;~i', '[/url]', $data);

				// <br /> should be empty.
				$empty_tags = array('br', 'hr');
				foreach ($empty_tags as $tag)
					$data = str_replace(array('&lt;' . $tag . '&gt;', '&lt;' . $tag . '/&gt;', '&lt;' . $tag . ' /&gt;'), '[' . $tag . ' /]', $data);

				// b, u, i, s, pre... basic tags.
				$closable_tags = array('b', 'u', 'i', 's', 'em', 'ins', 'del', 'pre', 'blockquote');
				foreach ($closable_tags as $tag)
				{
					$diff = substr_count($data, '&lt;' . $tag . '&gt;') - substr_count($data, '&lt;/' . $tag . '&gt;');
					$data = strtr($data, array('&lt;' . $tag . '&gt;' => '<' . $tag . '>', '&lt;/' . $tag . '&gt;' => '</' . $tag . '>'));

					if ($diff > 0)
						$data .= str_repeat('</' . $tag . '>', $diff);
				}

				// Do <img ... /> - with security... action= -> action-.
				preg_match_all('~&lt;img\s+src=((?:&quot;)?)((?:https?://|ftps?://)\S+?)\\1(?:\s+alt=(&quot;.*?&quot;|\S*?))?(?:\s?/)?&gt;~i', $data, $matches, PREG_PATTERN_ORDER);
				if (!empty($matches[0]))
				{
					$replaces = array();
					foreach ($matches[2] as $match => $imgtag)
					{
						$alt = empty($matches[3][$match]) ? '' : ' alt=' . preg_replace('~^&quot;|&quot;$~', '', $matches[3][$match]);

						// Remove action= from the URL - no funny business, now.
						if (preg_match('~action(=|%3d)(?!dlattach)~i', $imgtag) != 0)
							$imgtag = preg_replace('~action(=|%3d)(?!dlattach)~i', 'action-', $imgtag);

						// Check if the image is larger than allowed.
						if (!empty($modSettings['max_image_width']) && !empty($modSettings['max_image_height']))
						{
							list ($width, $height) = url_image_size($imgtag);

							if (!empty($modSettings['max_image_width']) && $width > $modSettings['max_image_width'])
							{
								$height = (int) (($modSettings['max_image_width'] * $height) / $width);
								$width = $modSettings['max_image_width'];
							}

							if (!empty($modSettings['max_image_height']) && $height > $modSettings['max_image_height'])
							{
								$width = (int) (($modSettings['max_image_height'] * $width) / $height);
								$height = $modSettings['max_image_height'];
							}

							// Set the new image tag.
							$replaces[$matches[0][$match]] = '[img width=' . $width . ' height=' . $height . $alt . ']' . $imgtag . '[/img]';
						}
						else
							$replaces[$matches[0][$match]] = '[img' . $alt . ']' . $imgtag . '[/img]';
					}

					$data = strtr($data, $replaces);
				}
			}

			if (!empty($modSettings['autoLinkUrls']))
			{
				// Are we inside tags that should be auto linked?
				$no_autolink_area = false;
				if (!empty($open_tags))
				{
					foreach ($open_tags as $open_tag)
						if (in_array($open_tag['tag'], $no_autolink_tags))
							$no_autolink_area = true;
				}

				// Don't go backwards.
				//!!! Don't think is the real solution....
				$lastAutoPos = isset($lastAutoPos) ? $lastAutoPos : 0;
				if ($pos < $lastAutoPos)
					$no_autolink_area = true;
				$lastAutoPos = $pos;

				if (!$no_autolink_area)
				{
					// Parse any URLs.... have to get rid of the @ problems some things cause... stupid email addresses.
					if (!isset($disabled['url']) && (strpos($data, '://') !== false || strpos($data, 'www.') !== false || strpos($data,'bitcoin:') !==false))
					{
						// Switch out quotes really quick because they can cause problems.
						$data = strtr($data, array('&#039;' => '\'', '&nbsp;' => $context['utf8'] ? "\xC2\xA0" : "\xA0", '&quot;' => '>">', '"' => '<"<', '&lt;' => '<lt<'));

						// Can't make use of $non_breaking_space in the URL regexes (that definition won't work without the "u" modifier).
						$nbsp = $context['utf8'] ? '\xc2\xa0' : '\xa0';

						// Only do this if the preg survives.
						if (is_string($result = preg_replace(array(
							'~(?<=[\s>\.(;\'"]|' . $nbsp . '|^)((?:http|https|ftp|ftps)://[\w\-_%@:|]+(?:\.[\w\-_%]+)*(?::\d+)?(?:/[\w\-_\~%\.@,\?&;=#(){}+:\'\\\\]*)*[/\w\-_\~%@\?;=#}\\\\])~i', 
							'~(?<=[\s>(;\'<]|' . $nbsp . '|^)(www(?:\.[\w\-_]+)+(?::\d+)?(?:/[\w\-_\~%\.@,\?&;=#(){}+:\'\\\\]*)*[/\w\-_\~%@\?;=#}\\\\])~i',
							'~bitcoin:([-A-Za-z0-9._:/?#!%@$()*+,;=]{25,})~i'
						), array(
							'[url]$1[/url]',
							'[url=http://$1]$1[/url]',
							'[url]bitcoin:$1[/url]'
						), $data)))
							$data = $result;

						$data = strtr($data, array('\'' => '&#039;', $context['utf8'] ? "\xC2\xA0" : "\xA0" => '&nbsp;', '>">' => '&quot;', '<"<' => '"', '<lt<' => '&lt;'));
					}

					// Next, emails...
					if (!isset($disabled['email']) && strpos($data, '@') !== false)
					{
						$data = preg_replace('~(?<=[\?\s' . $non_breaking_space . '\[\]()*\\\;>]|^)([\w\-\.]{1,80}@[\w\-]+\.[\w\-\.]+[\w\-])(?=[?,\s' . $non_breaking_space . '\[\]()*\\\]|$|<br />|&nbsp;|&gt;|&lt;|&quot;|&#039;|\.(?:\.|;|&nbsp;|\s|$|<br />))~' . ($context['utf8'] ? 'u' : ''), '[email]$1[/email]', $data);
						$data = preg_replace('~(?<=<br />)([\w\-\.]{1,80}@[\w\-]+\.[\w\-\.]+[\w\-])(?=[?\.,;\s' . $non_breaking_space . '\[\]()*\\\]|$|<br />|&nbsp;|&gt;|&lt;|&quot;|&#039;)~' . ($context['utf8'] ? 'u' : ''), '[email]$1[/email]', $data);
						// theymos - infinite loop
						if($pos > 1000 && strpos(substr($message, $pos-100), '[email][email][email][email]') !== false)
							return 'INVALID BBCODE: loop, probably unclosed tags (2)';
					}
				}
			}
			
			$data = strtr($data, array("\t" => '&nbsp;&nbsp;&nbsp;'));

			if (!empty($modSettings['fixLongWords']) && $modSettings['fixLongWords'] > 5)
			{
				// This is SADLY and INCREDIBLY browser dependent.
				if ($context['browser']['is_gecko'] || $context['browser']['is_konqueror'])
					$breaker = '<span style="margin: 0 -0.5ex 0 0;"> </span>';
				// Opera...
				elseif ($context['browser']['is_opera'])
					$breaker = '<span style="margin: 0 -0.65ex 0 -1px;"> </span>';
				// Internet Explorer...
				else
					$breaker = '<span style="width: 0; margin: 0 -0.6ex 0 -1px;"> </span>';

				// PCRE will not be happy if we don't give it a short.
				$modSettings['fixLongWords'] = (int) min(65535, $modSettings['fixLongWords']);

				// The idea is, find words xx long, and then replace them with xx + space + more.
				if (strlen($data) > $modSettings['fixLongWords'])
				{
					// This is done in a roundabout way because $breaker has "long words" :P.
					$data = strtr($data, array($breaker => '< >', '&nbsp;' => $context['utf8'] ? "\xC2\xA0" : "\xA0"));
					$data = preg_replace_callback(
						'~(?<=[>;:!? ' . $non_breaking_space . '\]()]|^)([\w' . ($context['utf8'] ? '\pL' : '') . '\.]{' . $modSettings['fixLongWords'] . ',})~' . ($context['utf8'] ? 'u' : ''),
						'word_break__preg_callback',
						$data);
					$data = strtr($data, array('< >' => $breaker, $context['utf8'] ? "\xC2\xA0" : "\xA0" => '&nbsp;'));
				}
			}

			// Do any smileys!
			if ($smileys === true)
				parsesmileys($data);

			// If it wasn't changed, no copying or other boring stuff has to happen!
			if ($data != substr($message, $last_pos, $pos - $last_pos + 1))
			{
				$message = substr($message, 0, $last_pos) . $data . substr($message, $pos + 1);

				// Since we changed it, look again incase we added or removed a tag.  But we don't want to skip any.
				$old_pos = strlen($data) + $last_pos - 1;
				$pos = strpos($message, '[', $last_pos);
				$pos = $pos === false ? $old_pos : min($pos, $old_pos);
			}
		}

		// Are we there yet?  Are we there yet?
		if ($pos >= strlen($message) - 1)
			break;

		$tags = strtolower(substr($message, $pos + 1, 1));

		if ($tags == '/' && !empty($open_tags))
		{
			$pos2 = strpos($message, ']', $pos + 1);
			if ($pos2 == $pos + 2)
				continue;
			$look_for = strtolower(substr($message, $pos + 2, $pos2 - $pos - 2));

			$to_close = array();
			$block_level = null;
			do
			{
				$tag = array_pop($open_tags);
				if (!$tag)
					break;

				if (!empty($tag['block_level']))
				{
					// Only find out if we need to.
					if ($block_level === false)
					{
						array_push($open_tags, $tag);
						break;
					}

					// The idea is, if we are LOOKING for a block level tag, we can close them on the way.
					if (strlen($look_for) > 0 && isset($bbc_codes[$look_for[0]]))
					{
						foreach ($bbc_codes[$look_for[0]] as $temp)
							if ($temp['tag'] == $look_for)
							{
								$block_level = !empty($temp['block_level']);
								break;
							}
					}

					if ($block_level !== true)
					{
						$block_level = false;
						array_push($open_tags, $tag);
						break;
					}
				}

				$to_close[] = $tag;
			}
			while ($tag['tag'] != $look_for);

			// Did we just eat through everything and not find it?
			if ((empty($open_tags) && (empty($tag) || $tag['tag'] != $look_for)))
			{
				$tablewarn = false;
				for($cc=count($to_close)-1;$cc>=0;$cc--) {
					if($to_close[$cc]['tag'] == 'table')
						$tablewarn = true;
					if($tablewarn && (in_array($to_close[$cc]['tag'], array('td', 'tr'))))
						return 'INVALID BBCODE: close of unopened tag in table (2)';
				}
				unset($cc, $tablewarn);
				$open_tags = $to_close;
				continue;
			}
			elseif (!empty($to_close) && $tag['tag'] != $look_for)
			{
				if ($block_level === null && isset($look_for[0], $bbc_codes[$look_for[0]]))
				{
					foreach ($bbc_codes[$look_for[0]] as $temp)
						if ($temp['tag'] == $look_for)
						{
							$block_level = !empty($temp['block_level']);
							break;
						}
				}

				// We're not looking for a block level tag (or maybe even a tag that exists...)
				if (!$block_level)
				{
					foreach ($to_close as $tag)
						array_push($open_tags, $tag);
					continue;
				}
			}

			foreach ($to_close as $tag)
			{
				$message = substr($message, 0, $pos) . $tag['after'] . substr($message, $pos2 + 1);
				$pos += strlen($tag['after']);
				$pos2 = $pos - 1;

				// See the comment at the end of the big loop - just eating whitespace ;).
				if (!empty($tag['block_level']) && substr($message, $pos, 6) == '<br />')
					$message = substr($message, 0, $pos) . substr($message, $pos + 6);
				if (!empty($tag['trim']) && $tag['trim'] != 'inside' && preg_match('~(<br />|&nbsp;|\s)*~', substr($message, $pos), $matches) != 0)
					$message = substr($message, 0, $pos) . substr($message, $pos + strlen($matches[0]));
			}

			if (!empty($to_close))
			{
				$to_close = array();
				$pos--;
			}

			continue;
		}

		// No tags for this character, so just keep going (fastest possible course.)
		if (!isset($bbc_codes[$tags]))
			continue;

		$inside = empty($open_tags) ? null : $open_tags[count($open_tags) - 1];
		$tag = null;
		foreach ($bbc_codes[$tags] as $possible)
		{
			// Not a match?
			if (strtolower(substr($message, $pos + 1, strlen($possible['tag']))) != $possible['tag'])
				continue;

			$next_c = substr($message, $pos + 1 + strlen($possible['tag']), 1);

			// A test validation?
			if (isset($possible['test']) && preg_match('~^' . $possible['test'] . '~', substr($message, $pos + 1 + strlen($possible['tag']) + 1)) == 0)
				continue;
			// Do we want parameters?
			elseif (!empty($possible['parameters']))
			{
				if ($next_c != ' ')
					continue;
			}
			elseif (isset($possible['type']))
			{
				// Do we need an equal sign?
				if (in_array($possible['type'], array('unparsed_equals', 'unparsed_commas', 'unparsed_commas_content', 'unparsed_equals_content', 'parsed_equals')) && $next_c != '=')
					continue;
				// Maybe we just want a /...
				if ($possible['type'] == 'closed' && $next_c != ']' && substr($message, $pos + 1 + strlen($possible['tag']), 2) != '/]' && substr($message, $pos + 1 + strlen($possible['tag']), 3) != ' /]')
					continue;
				// An immediate ]?
				if ($possible['type'] == 'unparsed_content' && $next_c != ']')
					continue;
			}
			// No type means 'parsed_content', which demands an immediate ] without parameters!
			elseif ($next_c != ']')
				continue;

			// Check allowed tree?
			if (isset($possible['require_parents']) && ($inside === null || !in_array($inside['tag'], $possible['require_parents'])))
				continue;
			elseif (isset($inside['require_children']) && !in_array($possible['tag'], $inside['require_children']))
				continue;
			// If this is in the list of disallowed child tags, don't parse it.
			elseif (isset($inside['disallow_children']) && in_array($possible['tag'], $inside['disallow_children']))
				continue;

			$pos1 = $pos + 1 + strlen($possible['tag']) + 1;

			// This is long, but it makes things much easier and cleaner.
			if (!empty($possible['parameters']))
			{
				$preg = array();
				foreach ($possible['parameters'] as $p => $info)
					$preg[] = '(\s+' . $p . '=' . (empty($info['quoted']) ? '' : '&quot;') . (isset($info['match']) ? $info['match'] : '(.+?)') . (empty($info['quoted']) ? '' : '&quot;') . ')' . (empty($info['optional']) ? '' : '?');

				// Okay, this may look ugly and it is, but it's not going to happen much and it is the best way of allowing any order of parameters but still parsing them right.
				$match = false;
				$orders = permute($preg);
				foreach ($orders as $p)
					if (preg_match('~^' . implode('', $p) . '\]~i', substr($message, $pos1 - 1), $matches) != 0)
					{
						$match = true;
						break;
					}

				// Didn't match our parameter list, try the next possible.
				if (!$match)
					continue;

				$params = array();
				for ($i = 1, $n = count($matches); $i < $n; $i += 2)
				{
					$key = strtok(ltrim($matches[$i]), '=');
					if (isset($possible['parameters'][$key]['value']))
						$params['{' . $key . '}'] = strtr($possible['parameters'][$key]['value'], array('$1' => $matches[$i + 1]));
					elseif (isset($possible['parameters'][$key]['validate']))
						$params['{' . $key . '}'] = $possible['parameters'][$key]['validate']($matches[$i + 1]);
					else
						$params['{' . $key . '}'] = $matches[$i + 1];

					// Just to make sure: replace any $ or { so they can't interpolate wrongly.
					$params['{' . $key . '}'] = strtr($params['{' . $key . '}'], array('$' => '&#036;', '{' => '&#123;'));
				}

				foreach ($possible['parameters'] as $p => $info)
				{
					if (!isset($params['{' . $p . '}']))
						$params['{' . $p . '}'] = '';
				}

				$tag = $possible;

				// Put the parameters into the string.
				if (isset($tag['before']))
					$tag['before'] = strtr($tag['before'], $params);
				if (isset($tag['after']))
					$tag['after'] = strtr($tag['after'], $params);
				if (isset($tag['content']))
					$tag['content'] = strtr($tag['content'], $params);

				$pos1 += strlen($matches[0]) - 1;
			}
			else
				$tag = $possible;
			break;
		}

		// Item codes are complicated buggers... they are implicit [li]s and can make [list]s!
		if ($smileys !== false && $tag === null && isset($itemcodes[substr($message, $pos + 1, 1)]) && substr($message, $pos + 2, 1) == ']' && !isset($disabled['list']) && !isset($disabled['li']))
		{
			if (substr($message, $pos + 1, 1) == '0' && !in_array(substr($message, $pos - 1, 1), array(';', ' ', "\t", '>')))
				continue;
			$tag = $itemcodes[substr($message, $pos + 1, 1)];

			// First let's set up the tree: it needs to be in a list, or after an li.
			if ($inside === null || ($inside['tag'] != 'list' && $inside['tag'] != 'li'))
			{
				$open_tags[] = array(
					'tag' => 'list',
					'after' => '</ul>',
					'block_level' => true,
					'require_children' => array('li'),
					'disallow_children' => isset($inside['disallow_children']) ? $inside['disallow_children'] : null,
				);
				$code = '<ul style="margin-top: 0; margin-bottom: 0;">';
			}
			// We're in a list item already: another itemcode?  Close it first.
			elseif ($inside['tag'] == 'li')
			{
				array_pop($open_tags);
				$code = '</li>';
			}
			else
				$code = '';

			// Now we open a new tag.
			$open_tags[] = array(
				'tag' => 'li',
				'after' => '</li>',
				'trim' => 'outside',
				'block_level' => true,
				'disallow_children' => isset($inside['disallow_children']) ? $inside['disallow_children'] : null,
			);

			// First, open the tag...
			$code .= '<li' . ($tag == '' ? '' : ' type="' . $tag . '"') . '>';
			$message = substr($message, 0, $pos) . $code . substr($message, $pos + 3);
			$pos += strlen($code) - 1;

			// Next, find the next break (if any.)  If there's more itemcode after it, keep it going - otherwise close!
			$pos2 = strpos($message, '<br />', $pos);
			$pos3 = strpos($message, '[/', $pos);
			if ($pos2 !== false && ($pos2 <= $pos3 || $pos3 === false))
			{
				preg_match('~^(<br />|&nbsp;|\s|\[)+~', substr($message, $pos2 + 6), $matches);
				$message = substr($message, 0, $pos2) . (!empty($matches[0]) && substr($matches[0], -1) == '[' ? '[/li]' : '[/li][/list]') . substr($message, $pos2);

				$open_tags[count($open_tags) - 2]['after'] = '</ul>';
			}
			// Tell the [list] that it needs to close specially.
			else
			{
				if(count($open_tags)<2) {
					return 'INVALID BBCODE: messed-up itemcodes';
				}
				// Move the li over, because we're not sure what we'll hit.
				$open_tags[count($open_tags) - 1]['after'] = '';
				$open_tags[count($open_tags) - 2]['after'] = '</li></ul>';
			}

			continue;
		}

		// Implicitly close lists and tables if something other than what's required is in them.  This is needed for itemcode.
		if ($tag === null && $inside !== null && !empty($inside['require_children']))
		{
			array_pop($open_tags);

			$message = substr($message, 0, $pos) . $inside['after'] . substr($message, $pos);
			$pos += strlen($inside['after']) - 1;
		}

		// No tag?  Keep looking, then.  Silly people using brackets without actual tags.
		if ($tag === null)
			continue;

		// Propagate the list to the child (so wrapping the disallowed tag won't work either.)
		if (isset($inside['disallow_children']))
			$tag['disallow_children'] = isset($tag['disallow_children']) ? array_unique(array_merge($tag['disallow_children'], $inside['disallow_children'])) : $inside['disallow_children'];

		// Is this tag disabled?
		if (isset($disabled[$tag['tag']]))
		{
			if (!isset($tag['disabled_before']) && !isset($tag['disabled_after']) && !isset($tag['disabled_content']))
			{
				$tag['before'] = !empty($tag['block_level']) ? '<div>' : '';
				$tag['after'] = !empty($tag['block_level']) ? '</div>' : '';
				$tag['content'] = isset($tag['type']) && $tag['type'] == 'closed' ? '' : (!empty($tag['block_level']) ? '<div>$1</div>' : '$1');
			}
			elseif (isset($tag['disabled_before']) || isset($tag['disabled_after']))
			{
				$tag['before'] = isset($tag['disabled_before']) ? $tag['disabled_before'] : (!empty($tag['block_level']) ? '<div>' : '');
				$tag['after'] = isset($tag['disabled_after']) ? $tag['disabled_after'] : (!empty($tag['block_level']) ? '</div>' : '');
			}
			else
				$tag['content'] = $tag['disabled_content'];
		}

		// The only special case is 'html', which doesn't need to close things.
		if (!empty($tag['block_level']) && $tag['tag'] != 'html' && empty($inside['block_level']))
		{
			$n = count($open_tags) - 1;
			while (empty($open_tags[$n]['block_level']) && $n >= 0)
				$n--;

			// Close all the non block level tags so this tag isn't surrounded by them.
			for ($i = count($open_tags) - 1; $i > $n; $i--)
			{
				$message = substr($message, 0, $pos) . $open_tags[$i]['after'] . substr($message, $pos);
				$pos += strlen($open_tags[$i]['after']);
				$pos1 += strlen($open_tags[$i]['after']);

				// Trim or eat trailing stuff... see comment at the end of the big loop.
				if (!empty($open_tags[$i]['block_level']) && substr($message, $pos, 6) == '<br />')
					$message = substr($message, 0, $pos) . substr($message, $pos + 6);
				if (!empty($open_tags[$i]['trim']) && $tag['trim'] != 'inside' && preg_match('~(<br />|&nbsp;|\s)*~', substr($message, $pos), $matches) != 0)
					$message = substr($message, 0, $pos) . substr($message, $pos + strlen($matches[0]));

				array_pop($open_tags);
			}
		}

		// No type means 'parsed_content'.
		if (!isset($tag['type']))
		{
			// !!! Check for end tag first, so people can say "I like that [i] tag"?
			$open_tags[] = $tag;
			$message = substr($message, 0, $pos) . $tag['before'] . substr($message, $pos1);
			$pos += strlen($tag['before']) - 1;
		}
		// Don't parse the content, just skip it.
		elseif ($tag['type'] == 'unparsed_content')
		{
			$pos2 = stripos($message, '[/' . substr($message, $pos + 1, strlen($tag['tag'])) . ']', $pos1);
			if ($pos2 === false)
				continue;

			$data = substr($message, $pos1, $pos2 - $pos1);

			if (!empty($tag['block_level']) && substr($data, 0, 6) == '<br />')
				$data = substr($data, 6);

			if (isset($tag['validate']))
				$tag['validate']($tag, $data, $disabled);

			$code = strtr($tag['content'], array('$1' => $data));
			$message = substr($message, 0, $pos) . $code . substr($message, $pos2 + 3 + strlen($tag['tag']));
			$pos += strlen($code) - 1;
		}
		// Don't parse the content, just skip it.
		elseif ($tag['type'] == 'unparsed_equals_content')
		{
			// The value may be quoted for some tags - check.
			if (isset($tag['quoted']))
			{
				$quoted = substr($message, $pos1, 6) == '&quot;';
				if ($tag['quoted'] != 'optional' && !$quoted)
					continue;

				if ($quoted)
					$pos1 += 6;
			}
			else
				$quoted = false;

			$pos2 = strpos($message, $quoted == false ? ']' : '&quot;]', $pos1);
			if ($pos2 === false)
				continue;
			$pos3 = stripos($message, '[/' . substr($message, $pos + 1, strlen($tag['tag'])) . ']', $pos2);
			if ($pos3 === false)
				continue;

			$data = array(
				substr($message, $pos2 + ($quoted == false ? 1 : 7), $pos3 - ($pos2 + ($quoted == false ? 1 : 7))),
				substr($message, $pos1, $pos2 - $pos1)
			);

			if (!empty($tag['block_level']) && substr($data[0], 0, 6) == '<br />')
				$data[0] = substr($data[0], 6);

			// Validation for my parking, please!
			if (isset($tag['validate']))
				$tag['validate']($tag, $data, $disabled);

			$code = strtr($tag['content'], array('$1' => $data[0], '$2' => $data[1]));
			$message = substr($message, 0, $pos) . $code . substr($message, $pos3 + 3 + strlen($tag['tag']));
			$pos += strlen($code) - 1;
		}
		// A closed tag, with no content or value.
		elseif ($tag['type'] == 'closed')
		{
			$pos2 = strpos($message, ']', $pos);
			$message = substr($message, 0, $pos) . $tag['content'] . substr($message, $pos2 + 1);
			$pos += strlen($tag['content']) - 1;
		}
		// This one is sorta ugly... :/.  Unforunately, it's needed for flash.
		elseif ($tag['type'] == 'unparsed_commas_content')
		{
			$pos2 = strpos($message, ']', $pos1);
			if ($pos2 === false)
				continue;
			$pos3 = stripos($message, '[/' . substr($message, $pos + 1, strlen($tag['tag'])) . ']', $pos2);
			if ($pos3 === false)
				continue;

			// We want $1 to be the content, and the rest to be csv.
			$data = explode(',', ',' . substr($message, $pos1, $pos2 - $pos1));
			$data[0] = substr($message, $pos2 + 1, $pos3 - $pos2 - 1);

			if (isset($tag['validate']))
				$tag['validate']($tag, $data, $disabled);

			$code = $tag['content'];
			foreach ($data as $k => $d)
				$code = strtr($code, array('$' . ($k + 1) => trim($d)));
			$message = substr($message, 0, $pos) . $code . substr($message, $pos3 + 3 + strlen($tag['tag']));
			$pos += strlen($code) - 1;
		}
		// This has parsed content, and a csv value which is unparsed.
		elseif ($tag['type'] == 'unparsed_commas')
		{
			$pos2 = strpos($message, ']', $pos1);
			if ($pos2 === false)
				continue;

			$data = explode(',', substr($message, $pos1, $pos2 - $pos1));

			if (isset($tag['validate']))
				$tag['validate']($tag, $data, $disabled);

			// Fix after, for disabled code mainly.
			foreach ($data as $k => $d)
				$tag['after'] = strtr($tag['after'], array('$' . ($k + 1) => trim($d)));

			$open_tags[] = $tag;

			// Replace them out, $1, $2, $3, $4, etc.
			$code = $tag['before'];
			foreach ($data as $k => $d)
				$code = strtr($code, array('$' . ($k + 1) => trim($d)));
			$message = substr($message, 0, $pos) . $code . substr($message, $pos2 + 1);
			$pos += strlen($code) - 1;
		}
		// A tag set to a value, parsed or not.
		elseif ($tag['type'] == 'unparsed_equals' || $tag['type'] == 'parsed_equals')
		{
			// The value may be quoted for some tags - check.
			if (isset($tag['quoted']))
			{
				$quoted = substr($message, $pos1, 6) == '&quot;';
				if ($tag['quoted'] != 'optional' && !$quoted)
					continue;

				if ($quoted)
					$pos1 += 6;
			}
			else
				$quoted = false;

			$pos2 = strpos($message, $quoted == false ? ']' : '&quot;]', $pos1);
			if ($pos2 === false)
				continue;

			$data = substr($message, $pos1, $pos2 - $pos1);

			// Validation for my parking, please!
			if (isset($tag['validate']))
				$tag['validate']($tag, $data, $disabled);

			// For parsed content, we must recurse to avoid security problems.
			if ($tag['type'] != 'unparsed_equals')
				$data = parse_bbc($data);

			$tag['after'] = strtr($tag['after'], array('$1' => $data));

			$open_tags[] = $tag;

			$code = strtr($tag['before'], array('$1' => $data));
			$message = substr($message, 0, $pos) . $code . substr($message, $pos2 + ($quoted == false ? 1 : 7));
			$pos += strlen($code) - 1;
		}

		// If this is block level, eat any breaks after it.
		if (!empty($tag['block_level']) && substr($message, $pos + 1, 6) == '<br />')
			$message = substr($message, 0, $pos + 1) . substr($message, $pos + 7);

		// Are we trimming outside this tag?
		if (!empty($tag['trim']) && $tag['trim'] != 'outside' && preg_match('~(<br />|&nbsp;|\s)*~', substr($message, $pos + 1), $matches) != 0)
			$message = substr($message, 0, $pos + 1) . substr($message, $pos + 1 + strlen($matches[0]));
	}

	// Close any remaining tags.
	while ($tag = array_pop($open_tags)) {
		if(in_array($tag['tag'], array('table','td','tr','th')))
			return 'INVALID BBCODE: close of unopened tag in table (1)';
		$message .= $tag['after'];
	}

	if (substr($message, 0, 1) == ' ')
		$message = '&nbsp;' . substr($message, 1);

	// Cleanup whitespace.
	$message = strtr($message, array('  ' => ' &nbsp;', "\r" => '', "\n" => '<br />', '<br /> ' => '<br />&nbsp;', '&#13;' => "\n"));
	
	if(in_array('ugc', $local_disable))
		$message = str_replace('<a class="ul"', '<a rel="ugc" class="ul"', $message);

	// Cache the output if it took some time...
	if (isset($cache_key, $cache_t) && array_sum(explode(' ', microtime())) - array_sum(explode(' ', $cache_t)) > 0.05)
		cache_put_data($cache_key, $message, 600);

	ECHO "d";

	return $message;
}

// Parse smileys in the passed message.
function parsesmileys(&$message)
{
	global $modSettings, $db_prefix, $txt, $user_info, $context;
	static $smileyfromcache = array(), $smileytocache = array();

	// No smiley set at all?!
	if ($user_info['smiley_set'] == 'none')
		return;

	// If the smiley array hasn't been set, do it now.
	if (empty($smileyfromcache))
	{
		// Use the default smileys if it is disabled. (better for "portability" of smileys.)
		if (empty($modSettings['smiley_enable']))
		{
			$smileysfrom = array('>:D', ':D', '::)', '>:(', ':)', ';)', ';D', ':(', ':o', '8)', ':P', '???', ':-[', ':-X', ':-*', ':\'(', ':-\\', '^-^', 'O0', 'C:-)', '0:)');
			$smileysto = array('evil.gif', 'cheesy.gif', 'rolleyes.gif', 'angry.gif', 'smiley.gif', 'wink.gif', 'grin.gif', 'sad.gif', 'shocked.gif', 'cool.gif', 'tongue.gif', 'huh.gif', 'embarrassed.gif', 'lipsrsealed.gif', 'kiss.gif', 'cry.gif', 'undecided.gif', 'azn.gif', 'afro.gif', 'police.gif', 'angel.gif');
			$smileysdescs = array('', $txt[289], $txt[450], $txt[288], $txt[287], $txt[292], $txt[293], $txt[291], $txt[294], $txt[295], $txt[451], $txt[296], $txt[526], $txt[527], $txt[529], $txt[530], $txt[528], '', '', '', '');
		}
		else
		{
			// Load the smileys in reverse order by length so they don't get parsed wrong.
			if (($temp = cache_get_data('parsing_smileys', 480)) == null)
			{
				$result = db_query("
					SELECT code, filename, description
					FROM {$db_prefix}smileys", __FILE__, __LINE__);
				$smileysfrom = array();
				$smileysto = array();
				$smileysdescs = array();
				while ($row = mysql_fetch_assoc($result))
				{
					$smileysfrom[] = $row['code'];
					$smileysto[] = $row['filename'];
					$smileysdescs[] = $row['description'];
				}
				mysql_free_result($result);

				cache_put_data('parsing_smileys', array($smileysfrom, $smileysto, $smileysdescs), 480);
			}
			else
				list ($smileysfrom, $smileysto, $smileysdescs) = $temp;
		}

		// The non-breaking-space is a complex thing...
		$non_breaking_space = $context['utf8'] ? ($context['server']['complex_preg_chars'] ? '\x{A0}' : pack('C*', 0xC2, 0xA0)) : '\xA0';

		// This smiley regex makes sure it doesn't parse smileys within code tags (so [url=mailto:David@bla.com] doesn't parse the :D smiley)
		for ($i = 0, $n = count($smileysfrom); $i < $n; $i++)
		{
			$smileyfromcache[] = '/(?<=[>:\?\.\s' . $non_breaking_space . '[\]()*\\\;]|^)(' . preg_quote($smileysfrom[$i], '/') . '|' . preg_quote(htmlspecialchars($smileysfrom[$i], ENT_QUOTES), '/') . ')(?=[^[:alpha:]0-9]|$)/' . ($context['utf8'] ? 'u' : '');
			// Escape a bunch of smiley-related characters in the description so it doesn't get a double dose :P.
			$smileytocache[] = '<img src="' . htmlspecialchars($modSettings['smileys_url'] . '/' . $user_info['smiley_set'] . '/' . $smileysto[$i]) . '" alt="' . strtr(htmlspecialchars($smileysdescs[$i]), array(':' => '&#58;', '(' => '&#40;', ')' => '&#41;', '$' => '&#36;', '[' => '&#091;')) . '" border="0" />';
		}
	}

	// Replace away!
	// !!! There must be a way to speed this up.
	$message = preg_replace($smileyfromcache, $smileytocache, $message);
}

// Parses some bbc before sending into the database...
function preparsecode(&$message, $previewing = false)
{
	global $user_info, $modSettings, $context;


	// Clean up after nobbc ;).
	$message = preg_replace_callback('~\[nobbc\](.+?)\[/nobbc\]~is', 'nobbc__preg_callback', $message);

	//$message = preg_replace('~\[([^\]=\s]+)[^\]]*\](?' . '>\s|(?R))*?\[/\1\]\s?~i', '', $message);

	// Remove \r's... they're evil!
	$message = strtr($message, array("\r" => ''));

	// You won't believe this - but too many periods upsets apache it seems!
	$message = preg_replace('~\.{100,}~', '...', $message);

	// Trim off trailing quotes - these often happen by accident.
	while (substr($message, -7) == '[quote]')
		$message = substr($message, 0, -7);
	while (substr($message, 0, 8) == '[/quote]')
		$message = substr($message, 8);

	// Check if all code tags are closed.
	$codeopen = preg_match_all('~(\[code(?:=[^\]]+)?\])~is', $message, $dummy);
	$codeclose = preg_match_all('~(\[/code\])~is', $message, $dummy);

	// Close/open all code tags...
	if ($codeopen > $codeclose)
		$message .= str_repeat('[/code]', $codeopen - $codeclose);
	elseif ($codeclose > $codeopen)
		$message = str_repeat('[code]', $codeclose - $codeopen) . $message;

	// Now that we've fixed all the code tags, let's fix the img and url tags...
	$parts = preg_split('~(\[/code\]|\[code(?:=[^\]]+)?\])~i', $message, -1, PREG_SPLIT_DELIM_CAPTURE);

	// The regular expression non breaking space has many versions.
	$non_breaking_space = $context['utf8'] ? ($context['server']['complex_preg_chars'] ? '\x{A0}' : pack('C*', 0xC2, 0xA0)) : '\xA0';

	// Only mess with stuff outside [code] tags.
	for ($i = 0, $n = count($parts); $i < $n; $i++)
	{
		// It goes 0 = outside, 1 = begin tag, 2 = inside, 3 = close tag, repeat.
		if ($i % 4 == 0)
		{
			fixTags($parts[$i]);

			// Replace /me.+?\n with [me=name]dsf[/me]\n.
			if (strpos($user_info['name'], '[') !== false || strpos($user_info['name'], ']') !== false || strpos($user_info['name'], '\'') !== false || strpos($user_info['name'], '"') !== false)
				$parts[$i] = preg_replace('~(?:\A|\n)/me(?: |&nbsp;)([^\n]*)(?:\z)?~i', '[me=&quot;' . $user_info['name'] . '&quot;]$1[/me]', $parts[$i]);
			else
				$parts[$i] = preg_replace('~(?:\A|\n)/me(?: |&nbsp;)([^\n]*)(?:\z)?~i', '[me=' . $user_info['name'] . ']$1[/me]', $parts[$i]);

			if (!$previewing && strpos($parts[$i], '[html]') !== false)
			{
				//if (false && allowedTo('admin_forum'))
					//$parts[$i] = preg_replace('~\[html\](.+?)\[/html\]~ise', '\'[html]\' . strtr(un_htmlspecialchars(\'$1\'), array("\n" => \'&#13;\', \'  \' => \' &#32;\')) . \'[/html]\'', $parts[$i]);
				// We should edit them out, or else if an admin edits the message they will get shown...
				//else
				//{
					while (strpos($parts[$i], '[html]') !== false)
						$parts[$i] = preg_replace('~\[[/]?html\]~i', '', $parts[$i]);
				//}
			}

			// Let's look at the time tags...
			$parts[$i] = preg_replace_callback('~\[time(?:=(absolute))*\](.+?)\[/time\]~i', 'time_fix__preg_callback', $parts[$i]);

			$list_open = substr_count($parts[$i], '[list]') + substr_count($parts[$i], '[list ');
			$list_close = substr_count($parts[$i], '[/list]');
			if ($list_close - $list_open > 0)
				$parts[$i] = str_repeat('[list]', $list_close - $list_open) . $parts[$i];
			if ($list_open - $list_close > 0)
				$parts[$i] = $parts[$i] . str_repeat('[/list]', $list_open - $list_close);

			// Make sure all tags are lowercase.
			$parts[$i] = preg_replace_callback('~\[([/]?)(list|li|table|tr|td)((\s[^\]]+)*)\]~i', 'lowercase_tags__preg_callback', $parts[$i]);

			$mistake_fixes = array(
				// Find [table]s not followed by [tr].
				'~\[table\](?![\s' . $non_breaking_space . ']*\[tr\])~s' . ($context['utf8'] ? 'u' : '') => '[table][tr]',
				// Find [tr]s not followed by [td].
				'~\[tr\](?![\s' . $non_breaking_space . ']*\[td\])~s' . ($context['utf8'] ? 'u' : '') => '[tr][td]',
				// Find [/td]s not followed by something valid.
				'~\[/td\](?![\s' . $non_breaking_space . ']*(?:\[td\]|\[/tr\]|\[/table\]))~s' . ($context['utf8'] ? 'u' : '') => '[/td][/tr]',
				// Find [/tr]s not followed by something valid.
				'~\[/tr\](?![\s' . $non_breaking_space . ']*(?:\[tr\]|\[/table\]))~s' . ($context['utf8'] ? 'u' : '') => '[/tr][/table]',
				// Find [/td]s incorrectly followed by [/table].
				'~\[/td\][\s' . $non_breaking_space . ']*\[/table\]~s' . ($context['utf8'] ? 'u' : '') => '[/td][/tr][/table]',
				// Find [table]s, [tr]s, and [/td]s (possibly correctly) followed by [td].
				'~\[(table|tr|/td)\]([\s' . $non_breaking_space . ']*)\[td\]~s' . ($context['utf8'] ? 'u' : '') => '[$1]$2[_td_]',
				// Now, any [td]s left should have a [tr] before them.
				'~\[td\]~s' => '[tr][td]',
				// Look for [tr]s which are correctly placed.
				'~\[(table|/tr)\]([\s' . $non_breaking_space . ']*)\[tr\]~s' . ($context['utf8'] ? 'u' : '') => '[$1]$2[_tr_]',
				// Any remaining [tr]s should have a [table] before them.
				'~\[tr\]~s' => '[table][tr]',
				// Look for [/td]s followed by [/tr].
				'~\[/td\]([\s' . $non_breaking_space . ']*)\[/tr\]~s' . ($context['utf8'] ? 'u' : '') => '[/td]$1[_/tr_]',
				// Any remaining [/tr]s should have a [/td].
				'~\[/tr\]~s' => '[/td][/tr]',
				// Look for properly opened [li]s which aren't closed.
				'~\[li\]([^\[\]]+?)\[li\]~s' => '[li]$1[_/li_][_li_]',
				'~\[li\]([^\[\]]+?)$~s' => '[li]$1[/li]',
				// Lists - find correctly closed items/lists.
				'~\[/li\]([\s' . $non_breaking_space . ']*)\[/list\]~s' . ($context['utf8'] ? 'u' : '') => '[_/li_]$1[/list]',
				// Find list items closed and then opened.
				'~\[/li\]([\s' . $non_breaking_space . ']*)\[li\]~s' . ($context['utf8'] ? 'u' : '') => '[_/li_]$1[_li_]',
				// Now, find any [list]s or [/li]s followed by [li].
				'~\[(list(?: [^\]]*?)?|/li)\]([\s' . $non_breaking_space . ']*)\[li\]~s' . ($context['utf8'] ? 'u' : '') => '[$1]$2[_li_]',
				// Any remaining [li]s weren't inside a [list].
				'~\[li\]~' => '[list][li]',
				// Any remaining [/li]s weren't before a [/list].
				'~\[/li\]~' => '[/li][/list]',
				// Put the correct ones back how we found them.
				'~\[_(li|/li|td|tr|/tr)_\]~' => '[$1]',
			);

			// Fix up some use of tables without [tr]s, etc. (it has to be done more than once to catch it all.)
			for ($j = 0; $j < 3; $j++)
				$parts[$i] = preg_replace(array_keys($mistake_fixes), $mistake_fixes, $parts[$i]);
		}
	}

	// Put it back together!
	if (!$previewing)
		$message = strtr(implode('', $parts), array('  ' => '&nbsp; ', "\n" => '<br />', $context['utf8'] ? "\xC2\xA0" : "\xA0" => '&nbsp;'));
	else
		$message = strtr(implode('', $parts), array('  ' => '&nbsp; ', $context['utf8'] ? "\xC2\xA0" : "\xA0" => '&nbsp;'));

	// Now let's quickly clean up things that will slow our parser (which are common in posted code.)
	$message = strtr($message, array('[]' => '&#91;]', '[&#039;' => '&#91;&#039;'));
}

// This is very simple, and just removes things done by preparsecode.
function un_preparsecode($message)
{
	$parts = preg_split('~(\[/code\]|\[code(?:=[^\]]+)?\])~i', $message, -1, PREG_SPLIT_DELIM_CAPTURE);

	// We're going to unparse only the stuff outside [code]...
	for ($i = 0, $n = count($parts); $i < $n; $i++)
	{
		// If $i is a multiple of four (0, 4, 8, ...) then it's not a code section...
		if ($i % 4 == 0)
		{
			$parts[$i] = preg_replace_callback('~\[html\](.+?)\[/html\]~i', function($m){return '[html]' . strtr(htmlspecialchars(stripslashes($m[1]), ENT_QUOTES), array('&amp;#13;' => '<br />', '&amp;#32;' => ' ')) . '[/html]';}, $parts[$i]);

			// Attempt to un-parse the time to something less awful.
			$parts[$i] = preg_replace_callback('~\[time\](\d{0,10})\[/time\]~i', 'time_format__preg_callback', $parts[$i]);
		}
	}

	// Change breaks back to \n's and &nsbp; back to spaces.
	return preg_replace('~<br( /)?' . '>~', "\n", str_replace('&nbsp;', ' ', implode('', $parts)));
}

function action_fix__preg_callback($matches)
{
	return $matches[1] . preg_replace('~action(=|%3d)(?!dlattach)~i', 'action-', $matches[2]) . '[/img]';
}

function mime_convert__preg_callback($matches)
{
	$c = $matches[1];
	if (strlen($c) === 1 && ord($c[0]) <= 0x7F)
		return $c;
	elseif (strlen($c) === 2 && ord($c[0]) >= 0xC0 && ord($c[0]) <= 0xDF)
		return '&#' . (((ord($c[0]) ^ 0xC0) << 6) + (ord($c[1]) ^ 0x80)) . ';';
	elseif (strlen($c) === 3 && ord($c[0]) >= 0xE0 && ord($c[0]) <= 0xEF)
		return '&#' . (((ord($c[0]) ^ 0xE0) << 12) + ((ord($c[1]) ^ 0x80) << 6) + (ord($c[2]) ^ 0x80)) . ';';
	elseif (strlen($c) === 4 && ord($c[0]) >= 0xF0 && ord($c[0]) <= 0xF7)
		return '&#' . (((ord($c[0]) ^ 0xF0) << 18) + ((ord($c[1]) ^ 0x80) << 12) + ((ord($c[2]) ^ 0x80) << 6) + (ord($c[3]) ^ 0x80)) . ';';
	else
		return '';
}

function time_fix__preg_callback($matches)
{
	global $modSettings, $user_info;
	return '[time]' . (is_numeric($matches[2]) || @strtotime($matches[2]) == 0 ? $matches[2] : strtotime($matches[2]) - ($matches[1] == 'absolute' ? 0 : (($modSettings['time_offset'] + $user_info['time_offset']) * 3600))) . '[/time]';
}

function nobbc__preg_callback($matches)
{
	return '[nobbc]' . strtr($matches[1], array('[' => '&#91;', ']' => '&#93;', ':' => '&#58;', '@' => '&#64;')) . '[/nobbc]';
}

function lowercase_tags__preg_callback($matches)
{
	return '[' . $matches[1] . strtolower($matches[2]) . $matches[3] . ']';
}

function htmlspecial_html__preg_callback($matches)
{
	global $modSettings, $txt;
	static $charset = null;
	if ($charset === null)
		$charset = empty($modSettings['global_character_set']) ? $txt['lang_character_set'] : $modSettings['global_character_set'];

	return '[html]' . strtr(htmlspecialchars($matches[1], ENT_QUOTES, $charset), array('\\&quot;' => '&quot;', '&amp;#13;' => '<br />', '&amp;#32;' => ' ', '&amp;#91;' => '[', '&amp;#93;' => ']')) . '[/html]';
}

function time_format__preg_callback($matches)
{
	return '[time]' . timeformat($matches[1], false) . '[/time]';
}
function word_break__preg_callback($matches)
{
	global $modSettings, $context;
	return preg_replace('~(.{' . ($modSettings['fixLongWords'] - 1) . '})~' . ($context['utf8'] ? 'u' : ''), '$1< >', $matches[1]);
}

//this would normally transform the URL into a proxied URL, but here it does nothing
function proxyurl($url) {
	return $url;
}

?>
