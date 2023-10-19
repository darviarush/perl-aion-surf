# NAME

Aion::Surf - surfing by internet

# VERSION

0.0.0-prealpha

# SYNOPSIS

```perl
use Aion::Surf;
use Test::Mock::LWP;

get "http://api.xyz"  # --> []
```

# DESCRIPTION

Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.

# SUBROUTINES

## to_json ($data)

Translate data to json format.

```perl
my $data = {
    a => 10,
};

my $result = '{
    "a": 10
}';

to_json $data # -> $result

local $_ = $data;
to_json # -> $result
```

## from_json ($string)

Parse string in json format to perl structure.

```perl
from_json '{"a": 10}' # --> {a => 10}
```

## to_url_param (;$scalar)

Escape scalar to part of url search.

```perl
to_url_param "a b" # => a+b

[map to_url_param, "a b", "🦁"] # --> [qw/a+b %/]
```

## to_url_params (;$hash_ref)

Generates the search part of the url.

```perl
to_url_params {a => 1, b => [[1,2],3]}  # => a&b[][]&b[][]=2&b[]=3
```

1. Keys with undef values not stringify.
1. Empty value is empty.
1. `1` value stringify key only.
1. Keys stringify in alfabet order.

```perl
to_url_params {k => "", n => undef, f => 1}  # => f&k=
```

## parse_url (;$url)

Parses and normalizes url.

```perl
parse_url ""    # --> {}

local $_ = ["/page", "https://main.com/pager/mix"];
```

See also `URL::XS`.

## normalize_url (;$url)

Normalizes url.

```perl
normalize_url ""  # -> .3
```

See also `URI::URL`.

## surf (@params)

Send request by LWP::UserAgent and adapt response.

```perl
surf "https://ya.ru", cookie => {}  # -> .3
```

## head (;$)

Check resurce in internet. Returns `HTTP::Request` if exists resurce in internet, otherwice returns `undef`.

```perl
head "" # -> .3
```

## get (;$url)

Get resurce in internet.

```perl
get "http://127.0.0.1/" # -> .3
```

## post (;$url)

Add resurce in internet.

```perl
post ["", {a => 1, b => 2}] # -> .3
```

## put (;$url)

Create or update resurce in internet.

```perl
put  # -> .3
```

## patch (;$url)

Set attributes on resurce in internet.

```perl
my $aion_surf = Aion::Surf->new;
$aion_surf->patch  # -> .3
```

## del (;$url)

Delete resurce in internet.

```perl
del "" # -> .3
```

## chat_message ($chat_id, $message)

Sends a message to a telegram chat.

```perl
chat_message "ABCD", "hi!"  # -> .3
```

## bot_message (;$message)

Sends a message to a telegram bot.

```perl
bot_message "hi!" # -> .3
```

## tech_message (;$message)

Sends a message to a technical telegram channel.

```perl
tech_message "hi!" # -> .3
```

## bot_update ()

Receives the latest messages sent to the bot.

```perl
bot_update  # --> 
```

# SEE ALSO

* LWP::Simple
* LWP::Simple::Post
* HTTP::Request::Common
* WWW::Mechanize
* [An article about sending an HTTP request to a server](https://habr.com/ru/articles/63432/)

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
