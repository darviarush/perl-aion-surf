# NAME

Aion::Surf - surfing by internet

# VERSION

0.0.0-prealpha

# SYNOPSIS

```perl
use Aion::Surf;
use common::sense;

# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;
    my $response = HTTP::Response->new(200, "OK");

    given ($request->method . " " . $request->uri) {
        $response->content("get")    when $_ eq "GET http://example/ex";
        $response->content("head")   when $_ eq "HEAD http://example/ex";
        $response->content("post")   when $_ eq "POST http://example/ex";
        $response->content("put")    when $_ eq "PUT http://example/ex";
        $response->content("patch")  when $_ eq "PATCH http://example/ex";
        $response->content("delete") when $_ eq "DELETE http://example/ex";

        $response->content('{"a":10}')  when $_ eq "PATCH http://example/json";
        default {
            $response = HTTP::Response->new(404, "Not Found");
            $response->content("nf");
        }
    }

    $response
};

get "http://example/ex"             # => get
surf "http://example/ex"            # => get

head "http://example/ex"            # -> 1
head "http://example/not-found"     # -> ""

surf HEAD => "http://example/ex"    # -> 1
surf HEAD => "http://example/not-found"  # -> ""

[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/] # --> [qw/get 1 post put patch delete/]

patch "http://example/json" # --> {a => 10}

[map patch, qw! http://example/ex http://example/json !]  # --> ["patch", {a => 10}]

get ["http://example/ex", headers => {Accept => "*/*"}]  # => get
surf "http://example/ex", headers => [Accept => "*/*"]   # => get
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
}
';

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

[map to_url_param, "a b", "🦁"] # --> [qw/a+b %1F981/]
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
use DDP; p my $x=parse_url "";
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

## surf ([$method], $url, @params)

Send request by LWP::UserAgent and adapt response.

`@params` maybe:

* `query` - add query params to `$url`.
* `json` - body request set in json format. Add header `Content-Type: application/json; charset=utf-8`.
* `form` - body request set in url params format. Add header `Content-Type: application/x-www-form-urlencoded`.
* `headers` - add headers. If `header` is array ref, then add in the order specified. If `header` is hash ref, then add in the alphabet order.
* `cookies` - add cookies. Same as: `cookies => {go => "xyz", session => ["abcd", path => "/page"]}`.
* `response` - returns response (as HTTP::Response) by this reference.

```perl
my $req = "
";

# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;

    $request->as_string # -> $req

    my $response = HTTP::Response->new(200, "OK");
    $response
};


my $res = surf MAYBE_ANY_METHOD => "https://ya.ru", [
        'Accept' => '*/*,image/*',
    ],
    query => [x => 10, y => "🧨"],
    cookies => {
        go => "",
        session => ["abcd", path => "/page"],
    },
;
$res # -> .3
```

## head (;$)

Check resurce in internet. Returns `1` if exists resurce in internet, otherwice returns `""`.

## get (;$url)

Get content from resurce in internet.

## post (;$url)

Add content resurce in internet.

## put (;$url)

Create or update resurce in internet.

## patch (;$url)

Set attributes on resurce in internet.

## del (;$url)

Delete resurce in internet.

## chat_message ($chat_id, $message)

Sends a message to a telegram chat.

```perl
chat_message "ABCD", "hi!"  # => ok
```

## bot_message (;$message)

Sends a message to a telegram bot.

```perl
bot_message "hi!" # => ok
```

## tech_message (;$message)

Sends a message to a technical telegram channel.

```perl
tech_message "hi!" # => ok
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
