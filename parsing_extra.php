<?php
// these are the values that a guest would see on bitcointalk.org
function setReasonableValues()
{
        global $txt, $modSettings, $user_info, $context;
        
        define('WIRELESS', false);
        
        $context = array('browser'=>array());
        $context['browser']['is_gecko'] = true;
        $context['browser']['is_konqueror'] = false;
        $context['browser']['is_opera'] = false;
        $context['browser']['is_ie'] = false;

        $txt['lang_character_set'] = 'ISO-8859-1';
        $txt['smf238'] = 'Code';
        $txt['smf240'] = 'Quote';
        $txt['smf239'] = 'Quote from';
        $txt[176] = 'on';
        $txt['lang_locale'] = 'en_US';
        $txt[289] = 'Cheesy';
        $txt[450] = 'Roll Eyes';
        $txt[288] = 'Angry';
        $txt[287] = 'Smiley';
        $txt[292] = 'Wink';
        $txt[293] = 'Grin';
        $txt[291] = 'Sad';
        $txt[294] = 'Shocked';
        $txt[295] = 'Cool';
        $txt[451] = 'Tongue';
        $txt[296] = 'Huh';
        $txt[526] = 'Embarrassed';
        $txt[527] = 'Lips sealed';
        $txt[529] = 'Kiss';
        $txt[530] = 'Cry';
        $txt[528] = 'Undecided';
        $txt['smf10'] = '<b>Today</b> at ';
        $txt['smf10b'] = '<b>Yesterday</b> at ';
        $txt['days_short'] =  array('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
        $txt['days'] = array('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
        $txt['months_short'] = array(1 => 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
        $txt['months'] = array(1 => 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
        
        $modSettings['enableBBC'] = 1;
        $modSettings['cache_enable'] = 0;
        $modSettings['enablePostHTML'] = 0;
        $modSettings['max_image_width'] = 0;
        $modSettings['max_image_height'] = 0;
        $modSettings['autoLinkUrls'] = 1;
        $modSettings['fixLongWords'] = 80;
        $modSettings['smileys_url'] = 'https://bitcointalk.org/Smileys';
        $modSettings['time_offset'] = 0;
        $modSettings['todayMod'] = 1;

        // Need these from theymos
        $user_info['smiley_set'] = 'default';
        $user_info['time_offset'] = 0;
        $user_info['time_format'] = '%I:%M:%S %p';
}

//the cache functions are highly implementation-dependant, so here they are just no-ops
function cache_put_data($key, $value, $ttl = 120)
{
        return;
}

function cache_get_data($key, $ttl = 120)
{
        return;
}

function highlight_php_code($code)
{
        global $context;

        // Remove special characters.
        $code = un_htmlspecialchars(strtr($code, array('<br />' => "\n", "\t" => 'SMF_TAB();', '&#91;' => '[')));

        $oldlevel = error_reporting(0);

        // It's easier in 4.2.x+.
        if (@version_compare(PHP_VERSION, '4.2.0') == -1)
        {
                ob_start();
                @highlight_string($code);
                $buffer = str_replace(array("\n", "\r"), '', ob_get_contents());
                ob_end_clean();
        }
        else
                $buffer = str_replace(array("\n", "\r"), '', @highlight_string($code, true));

        error_reporting($oldlevel);

        // Yes, I know this is kludging it, but this is the best way to preserve tabs from PHP :P.
        $buffer = preg_replace('~SMF_TAB(</(font|span)><(font color|span style)="[^"]*?">)?\(\);~', "<pre style=\"display: inline;\">\t</pre>", $buffer);

        return strtr($buffer, array('\'' => '&#039;', '<code>' => '', '</code>' => ''));
}
function un_htmlspecialchars($string)
{
        return strtr($string, array_flip(get_html_translation_table(HTML_SPECIALCHARS, ENT_QUOTES)) + array('&#039;' => '\'', '&nbsp;' => ' '));
}

// Format a time to make it look purdy.
function timeformat($logTime, $show_today = true)
{
        global $user_info, $txt, $db_prefix, $modSettings, $func;

        // Offset the time.
        $time = $logTime + ($user_info['time_offset'] + $modSettings['time_offset']) * 3600;

        // We can't have a negative date (on Windows, at least.)
        if ($time < 0)
                $time = 0;

        // Today and Yesterday?
        if ($modSettings['todayMod'] >= 1 && $show_today === true)
        {
                // Get the current time.
                $nowtime = forum_time();

                $then = @getdate($time);
                $now = @getdate($nowtime);
                if(!$then)
                        $then = @getdate(0);
                if(!$now)
                        $now = @getdate(0);

                // Try to make something of a time format string...
                $s = strpos($user_info['time_format'], '%S') === false ? '' : ':%S';
                if (strpos($user_info['time_format'], '%H') === false && strpos($user_info['time_format'], '%T') === false)
                        $today_fmt = '%I:%M' . $s . ' %p';
                else
                        $today_fmt = '%H:%M' . $s;

                // Same day of the year, same year.... Today!
                if ($then['yday'] == $now['yday'] && $then['year'] == $now['year'])
                        return $txt['smf10'] . timeformat($logTime, $today_fmt);

                // Day-of-year is one less and same year, or it's the first of the year and that's the last of the year...
                if ($modSettings['todayMod'] == '2' && (($then['yday'] == $now['yday'] - 1 && $then['year'] == $now['year']) || ($now['yday'] == 0 && $then['year'] == $now['year'] - 1) && $then['mon'] == 12 && $then['mday'] == 31))
                        return $txt['smf10b'] . timeformat($logTime, $today_fmt);
        }

        $str = !is_bool($show_today) ? $show_today : $user_info['time_format'];

        if (setlocale(LC_TIME, $txt['lang_locale']))
        {
                foreach (array('%a', '%A', '%b', '%B') as $token)
                        if (strpos($str, $token) !== false)
                                $str = str_replace($token, $func['ucwords'](strftime_updated($token, (int)$time)), $str);
        }
        else
        {
                // Do-it-yourself time localization.  Fun.
                foreach (array('%a' => 'days_short', '%A' => 'days', '%b' => 'months_short', '%B' => 'months') as $token => $text_label)
                        if (strpos($str, $token) !== false)
                                $str = str_replace($token, $txt[$text_label][(int) strftime_updated($token === '%a' || $token === '%A' ? '%w' : '%m', $time)], $str);
                if (strpos($str, '%p'))
                        $str = str_replace('%p', (strftime_updated('%H', $time) < 12 ? 'am' : 'pm'), $str);
        }

        // Format any other characters..
        return strftime_updated($str, (int)$time);
}

function forum_time($use_user_offset = true, $timestamp = null)
{
        global $user_info, $modSettings;

        if ($timestamp === null)
                $timestamp = time();
        elseif ($timestamp == 0)
                return 0;

        return $timestamp + ($modSettings['time_offset'] + ($use_user_offset ? $user_info['time_offset'] : 0)) * 3600;
}

function safe_serialize($value)
{
        // Make sure we use the byte count for strings even when strlen() is overloaded by mb_strlen()
        if (function_exists('mb_internal_encoding') &&
                (((int) ini_get('mbstring.func_overload')) & 2))
        {
                $mbIntEnc = mb_internal_encoding();
                mb_internal_encoding('ASCII');
        }

        $out = _safe_serialize($value);

        if (isset($mbIntEnc))
                mb_internal_encoding($mbIntEnc);

        return $out;
}
function _safe_serialize($value)
{
        if(is_null($value))
                return 'N;';

        if(is_bool($value))
                return 'b:'. (int) $value .';';

        if(is_int($value))
                return 'i:'. $value .';';

        if(is_float($value))
                return 'd:'. str_replace(',', '.', $value) .';';

        if(is_string($value))
                return 's:'. strlen($value) .':"'. $value .'";';

        if(is_array($value))
        {
                $out = '';
                foreach($value as $k => $v)
                        $out .= _safe_serialize($k) . _safe_serialize($v);

                return 'a:'. count($value) .':{'. $out .'}';
        }

        // safe_serialize cannot serialize resources or objects.
        return false;
}

// This gets all possible permutations of an array.
function permute($array)
{
        $orders = array($array);

        $n = count($array);
        $p = range(0, $n);
        for ($i = 1; $i < $n; null)
        {
                $p[$i]--;
                $j = $i % 2 != 0 ? $p[$i] : 0;

                $temp = $array[$i];
                $array[$i] = $array[$j];
                $array[$j] = $temp;

                for ($i = 1; $p[$i] == 0; $i++)
                        $p[$i] = 1;

                $orders[] = $array;
        }

        return $orders;
}
// Fix any URLs posted - ie. remove 'javascript:'.
function fixTags(&$message)
{
  global $modSettings;

  // WARNING: Editing the below can cause large security holes in your forum.
  // Edit only if you are sure you know what you are doing.

  $fixArray = array(
    // [img]http://...[/img] or [img width=1]http://...[/img]
    array(
      'tag' => 'img',
      'protocols' => array('http', 'https'),
      'embeddedUrl' => false,
      'hasEqualSign' => false,
      'hasExtra' => true,
    ),
    // [url]http://...[/url]
    array(
      'tag' => 'url',
      'protocols' => array('http', 'https', 'bitcoin:', 'magnet:'),
      'embeddedUrl' => true,
      'hasEqualSign' => false,
    ),
    // [url=http://...]name[/url]
    array(
      'tag' => 'url',
      'protocols' => array('http', 'https', 'bitcoin:', 'magnet:'),
      'embeddedUrl' => true,
      'hasEqualSign' => true,
    ),
    // [iurl]http://...[/iurl]
    array(
      'tag' => 'iurl',
      'protocols' => array('http', 'https', 'bitcoin:', 'magnet:'),
      'embeddedUrl' => true,
      'hasEqualSign' => false,
    ),
    // [iurl=http://...]name[/iurl]
    array(
      'tag' => 'iurl',
      'protocols' => array('http', 'https', 'bitcoin:', 'magnet:'),
      'embeddedUrl' => true,
      'hasEqualSign' => true,
    ),
    // [ftp]ftp://...[/ftp]
    array(
      'tag' => 'ftp',
      'protocols' => array('ftp', 'ftps'),
      'embeddedUrl' => true,
      'hasEqualSign' => false,
    ),
    // [ftp=ftp://...]name[/ftp]
    array(
      'tag' => 'ftp',
      'protocols' => array('ftp', 'ftps'),
      'embeddedUrl' => true,
      'hasEqualSign' => true,
    ),
    // [flash]http://...[/flash]
    array(
      'tag' => 'flash',
      'protocols' => array('http', 'https'),
      'embeddedUrl' => false,
      'hasEqualSign' => false,
      'hasExtra' => true,
    ),
  );

  // Fix each type of tag.
  foreach ($fixArray as $param)
    fixTag($message, $param['tag'], $param['protocols'], $param['embeddedUrl'], $param['hasEqualSign'], !empty($param['hasExtra']));

  // Now fix possible security problems with images loading links automatically...
  $message = preg_replace_callback('~(\[img.*?\])(.+?)\[/img\]~is', 'action_fix__preg_callback', $message);

  // Limit the size of images posted?
  if (!empty($modSettings['max_image_width']) || !empty($modSettings['max_image_height']))
  {
    // Find all the img tags - with or without width and height.
    preg_match_all('~\[img(\s+width=\d+)?(\s+height=\d+)?(\s+width=\d+)?\](.+?)\[/img\]~is', $message, $matches, PREG_PATTERN_ORDER);

    $replaces = array();
    foreach ($matches[0] as $match => $dummy)
    {
      // If the width was after the height, handle it.
      $matches[1][$match] = !empty($matches[3][$match]) ? $matches[3][$match] : $matches[1][$match];

      // Now figure out if they had a desired height or width...
      $desired_width = !empty($matches[1][$match]) ? (int) substr(trim($matches[1][$match]), 6) : 0;
      $desired_height = !empty($matches[2][$match]) ? (int) substr(trim($matches[2][$match]), 7) : 0;

      // One was omitted, or both.  We'll have to find its real size...
      if (empty($desired_width) || empty($desired_height))
      {
        list ($width, $height) = url_image_size(un_htmlspecialchars($matches[4][$match])); //this is dead code, don't worry about url_image_size

        // They don't have any desired width or height!
        if (empty($desired_width) && empty($desired_height))
        {
          $desired_width = $width;
          $desired_height = $height;
        }
        // Scale it to the width...
        elseif (empty($desired_width) && !empty($height))
          $desired_width = (int) (($desired_height * $width) / $height);
        // Scale if to the height.
        elseif (!empty($width))
          $desired_height = (int) (($desired_width * $height) / $width);
      }

      // If the width and height are fine, just continue along...
      if ($desired_width <= $modSettings['max_image_width'] && $desired_height <= $modSettings['max_image_height'])
        continue;

      // Too bad, it's too wide.  Make it as wide as the maximum.
      if ($desired_width > $modSettings['max_image_width'] && !empty($modSettings['max_image_width']))
      {
        $desired_height = (int) (($modSettings['max_image_width'] * $desired_height) / $desired_width);
        $desired_width = $modSettings['max_image_width'];
      }

      // Now check the height, as well.  Might have to scale twice, even...
      if ($desired_height > $modSettings['max_image_height'] && !empty($modSettings['max_image_height']))
      {
        $desired_width = (int) (($modSettings['max_image_height'] * $desired_width) / $desired_height);
        $desired_height = $modSettings['max_image_height'];
      }

      $replaces[$matches[0][$match]] = '[img' . (!empty($desired_width) ? ' width=' . $desired_width : '') . (!empty($desired_height) ? ' height=' . $desired_height : '') . ']' . $matches[4][$match] . '[/img]';
    }

    // If any img tags were actually changed...
    if (!empty($replaces))
      $message = strtr($message, $replaces);
  }
}

function action_fix__preg_callback($matches)
{
  return $matches[1] . preg_replace('~action(=|%3d)(?!dlattach)~i', 'action-', $matches[2]) . '[/img]';
}

// Fix a specific class of tag - ie. url with =.
function fixTag(&$message, $myTag, $protocols, $embeddedUrl = false, $hasEqualSign = false, $hasExtra = false)
{
  global $boardurl, $scripturl;

  if (preg_match('~^([^:]+://[^/]+)~', $boardurl, $match) != 0)
    $domain_url = $match[1];
  else
    $domain_url = $boardurl . '/';

  $replaces = array();

  if ($hasEqualSign)
    preg_match_all('~\[(' . $myTag . ')=([^\]]*?)\](?:(.+?)\[/(' . $myTag . ')\])?~is', $message, $matches);
  else
    preg_match_all('~\[(' . $myTag . ($hasExtra ? '(?:[^\]]*?)' : '') . ')\](.+?)\[/(' . $myTag . ')\]~is', $message, $matches);

  foreach ($matches[0] as $k => $dummy)
  {
    // Remove all leading and trailing whitespace.
    $replace = trim($matches[2][$k]);
    $this_tag = $matches[1][$k];
    $this_close = $hasEqualSign ? (empty($matches[4][$k]) ? '' : $matches[4][$k]) : $matches[3][$k];

    $found = false;
    foreach ($protocols as $protocol)
    {
      if (strpos($protocol, ':') === false)
        $found = strncasecmp($replace, $protocol . '://', strlen($protocol) + 3) === 0;
      else
        $found = strncasecmp($replace, $protocol, strlen($protocol)) === 0;
      if ($found)
        break;
    }

    if (!$found && $protocols[0] == 'http')
    {
      if (substr($replace, 0, 1) == '/')
        $replace = $domain_url . $replace;
      elseif (substr($replace, 0, 1) == '?')
        $replace = $scripturl . $replace;
      elseif (substr($replace, 0, 1) == '#' && $embeddedUrl)
      {
        $replace = '#' . preg_replace('~[^A-Za-z0-9_\-#]~', '', substr($replace, 1));
        $this_tag = 'iurl';
        $this_close = 'iurl';
      }
      else
        $replace = $protocols[0] . '://' . $replace;
    }
    elseif (!$found)
      $replace = $protocols[0] . '://' . $replace;

    if ($hasEqualSign && $embeddedUrl)
      $replaces[$matches[0][$k]] = '[' . $this_tag . '=' . $replace . ']' . (empty($matches[4][$k]) ? '' : $matches[3][$k] . '[/' . $this_close . ']');
    elseif ($hasEqualSign)
      $replaces['[' . $matches[1][$k] . '=' . $matches[2][$k] . ']'] = '[' . $this_tag . '=' . $replace . ']';
    elseif ($embeddedUrl)
      $replaces['[' . $matches[1][$k] . ']' . $matches[2][$k] . '[/' . $matches[3][$k] . ']'] = '[' . $this_tag . '=' . $replace . ']' . $matches[2][$k] . '[/' . $this_close . ']';
    else
      $replaces['[' . $matches[1][$k] . ']' . $matches[2][$k] . '[/' . $matches[3][$k] . ']'] = '[' . $this_tag . ']' . $replace . '[/' . $this_close . ']';

  }

  foreach ($replaces as $k => $v)
  {
    if ($k == $v)
      unset($replaces[$k]);
  }

  if (!empty($replaces))
    $message = strtr($message, $replaces);
}

/**
 * Locale-formatted strftime_updated using \IntlDateFormatter (PHP 8.1 compatible)
 * This provides a cross-platform alternative to strftime_updated() for when it will be removed from PHP.
 * Note that output can be slightly different between libc sprintf and this function as it is using ICU.
 *
 * Usage:
 * use function \PHP81_BC\strftime_updated;
 * echo strftime_updated('%A %e %B %Y %X', new \DateTime('2021-09-28 00:00:00'), 'fr_FR');
 *
 * Original use:
 * \setlocale('fr_FR.UTF-8', LC_TIME);
 * echo \strftime_updated('%A %e %B %Y %X', strtotime('2021-09-28 00:00:00'));
 *
 * @param  string $format Date format
 * @param  integer|string|DateTime $timestamp Timestamp
 * @return string
 * @author BohwaZ <https://bohwaz.net/>
 */
function strftime_updated(string $format, $timestamp = null, ?string $locale = null): string
{
  if (null === $timestamp) {
    $timestamp = new \DateTime;
  }
  elseif (is_numeric($timestamp)) {
    $timestamp = date_create('@' . $timestamp);

    if ($timestamp) {
      $timestamp->setTimezone(new \DateTimezone(date_default_timezone_get()));
    }
  }
  elseif (is_string($timestamp)) {
    $timestamp = date_create($timestamp);
  }

  if (!($timestamp instanceof \DateTimeInterface)) {
    throw new \InvalidArgumentException('$timestamp argument is neither a valid UNIX timestamp, a valid date-time string or a DateTime object.');
  }

  $locale = substr((string) $locale, 0, 5);

  $intl_formats = [
    '%a' => 'EEE',  // An abbreviated textual representation of the day Sun through Sat
    '%A' => 'EEEE', // A full textual representation of the day Sunday through Saturday
    '%b' => 'MMM',  // Abbreviated month name, based on the locale  Jan through Dec
    '%B' => 'MMMM', // Full month name, based on the locale January through December
    '%h' => 'MMM',  // Abbreviated month name, based on the locale (an alias of %b) Jan through Dec
  ];

  $intl_formatter = function (\DateTimeInterface $timestamp, string $format) use ($intl_formats, $locale) {
    $tz = $timestamp->getTimezone();
    $date_type = \IntlDateFormatter::FULL;
    $time_type = \IntlDateFormatter::FULL;
    $pattern = '';

    // %c = Preferred date and time stamp based on locale
    // Example: Tue Feb 5 00:45:10 2009 for February 5, 2009 at 12:45:10 AM
    if ($format == '%c') {
      $date_type = \IntlDateFormatter::LONG;
      $time_type = \IntlDateFormatter::SHORT;
    }
    // %x = Preferred date representation based on locale, without the time
    // Example: 02/05/09 for February 5, 2009
    elseif ($format == '%x') {
      $date_type = \IntlDateFormatter::SHORT;
      $time_type = \IntlDateFormatter::NONE;
    }
    // Localized time format
    elseif ($format == '%X') {
      $date_type = \IntlDateFormatter::NONE;
      $time_type = \IntlDateFormatter::MEDIUM;
    }
    else {
      $pattern = $intl_formats[$format];
    }

    return (new \IntlDateFormatter($locale, $date_type, $time_type, $tz, null, $pattern))->format($timestamp);
  };

  // Same order as https://www.php.net/manual/en/function.strftime_updated.php
  $translation_table = [
    // Day
    '%a' => $intl_formatter,
    '%A' => $intl_formatter,
    '%d' => 'd',
    '%e' => function ($timestamp) {
      return sprintf('% 2u', $timestamp->format('j'));
    },
    '%j' => function ($timestamp) {
      // Day number in year, 001 to 366
      return sprintf('%03d', $timestamp->format('z')+1);
    },
    '%u' => 'N',
    '%w' => 'w',

    // Week
    '%U' => function ($timestamp) {
      // Number of weeks between date and first Sunday of year
      $day = new \DateTime(sprintf('%d-01 Sunday', $timestamp->format('Y')));
      return sprintf('%02u', 1 + ($timestamp->format('z') - $day->format('z')) / 7);
    },
    '%V' => 'W',
    '%W' => function ($timestamp) {
      // Number of weeks between date and first Monday of year
      $day = new \DateTime(sprintf('%d-01 Monday', $timestamp->format('Y')));
      return sprintf('%02u', 1 + ($timestamp->format('z') - $day->format('z')) / 7);
    },

    // Month
    '%b' => $intl_formatter,
    '%B' => $intl_formatter,
    '%h' => $intl_formatter,
    '%m' => 'm',

    // Year
    '%C' => function ($timestamp) {
      // Century (-1): 19 for 20th century
      return floor($timestamp->format('Y') / 100);
    },
    '%g' => function ($timestamp) {
      return substr($timestamp->format('o'), -2);
    },
    '%G' => 'o',
    '%y' => 'y',
    '%Y' => 'Y',

    // Time
    '%H' => 'H',
    '%k' => function ($timestamp) {
      return sprintf('% 2u', $timestamp->format('G'));
    },
    '%I' => 'h',
    '%l' => function ($timestamp) {
      return sprintf('% 2u', $timestamp->format('g'));
    },
    '%M' => 'i',
    '%p' => 'A', // AM PM (this is reversed on purpose!)
    '%P' => 'a', // am pm
    '%r' => 'h:i:s A', // %I:%M:%S %p
    '%R' => 'H:i', // %H:%M
    '%S' => 's',
    '%T' => 'H:i:s', // %H:%M:%S
    '%X' => $intl_formatter, // Preferred time representation based on locale, without the date

    // Timezone
    '%z' => 'O',
    '%Z' => 'T',

    // Time and Date Stamps
    '%c' => $intl_formatter,
    '%D' => 'm/d/Y',
    '%F' => 'Y-m-d',
    '%s' => 'U',
    '%x' => $intl_formatter,
  ];

  $out = preg_replace_callback('/(?<!%)(%[a-zA-Z])/', function ($match) use ($translation_table, $timestamp) {
    if ($match[1] == '%n') {
      return "\n";
    }
    elseif ($match[1] == '%t') {
      return "\t";
    }

    if (!isset($translation_table[$match[1]])) {
      throw new \InvalidArgumentException(sprintf('Format "%s" is unknown in time format', $match[1]));
    }

    $replace = $translation_table[$match[1]];

    if (is_string($replace)) {
      return $timestamp->format($replace);
    }
    else {
      return $replace($timestamp, $match[1]);
    }
  }, $format);

  $out = str_replace('%%', '%', $out);
  return $out;
}


?>
