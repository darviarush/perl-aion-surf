use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-surf!aion!surf/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Surf - surfing by internet
# 
# # VERSION
# 
# 0.0.0-prealpha
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

::is scalar do {get "http://example/ex"}, "get", 'get "http://example/ex"             # => get';
::is scalar do {surf "http://example/ex"}, "get", 'surf "http://example/ex"            # => get';

::is scalar do {head "http://example/ex"}, scalar do{1}, 'head "http://example/ex"            # -> 1';
::is scalar do {head "http://example/not-found"}, scalar do{""}, 'head "http://example/not-found"     # -> ""';

::is scalar do {surf HEAD => "http://example/ex"}, scalar do{1}, 'surf HEAD => "http://example/ex"    # -> 1';
::is scalar do {surf HEAD => "http://example/not-found"}, scalar do{""}, 'surf HEAD => "http://example/not-found"  # -> ""';

::is_deeply scalar do {[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/]}, scalar do {[qw/get 1 post put patch delete/]}, '[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/] # --> [qw/get 1 post put patch delete/]';

::is_deeply scalar do {patch "http://example/json"}, scalar do {{a => 10}}, 'patch "http://example/json" # --> {a => 10}';

::is_deeply scalar do {[map patch, qw! http://example/ex http://example/json !]}, scalar do {["patch", {a => 10}]}, '[map patch, qw! http://example/ex http://example/json !]  # --> ["patch", {a => 10}]';

::is scalar do {get ["http://example/ex", headers => {Accept => "*/*"}]}, "get", 'get ["http://example/ex", headers => {Accept => "*/*"}]  # => get';
::is scalar do {surf "http://example/ex", headers => [Accept => "*/*"]}, "get", 'surf "http://example/ex", headers => [Accept => "*/*"]   # => get';

# 
# # DESCRIPTION
# 
# Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.
# 
# # SUBROUTINES
# 
# ## to_json ($data)
# 
# Translate data to json format.
# 
done_testing; }; subtest 'to_json ($data)' => sub { 
my $data = {
    a => 10,
};

my $result = '{
   "a": 10
}
';

::is scalar do {to_json $data}, scalar do{$result}, 'to_json $data # -> $result';

local $_ = $data;
::is scalar do {to_json}, scalar do{$result}, 'to_json # -> $result';

# 
# ## from_json ($string)
# 
# Parse string in json format to perl structure.
# 
done_testing; }; subtest 'from_json ($string)' => sub { 
::is_deeply scalar do {from_json '{"a": 10}'}, scalar do {{a => 10}}, 'from_json \'{"a": 10}\' # --> {a => 10}';

# 
# ## to_url_param (;$scalar)
# 
# Escape scalar to part of url search.
# 
done_testing; }; subtest 'to_url_param (;$scalar)' => sub { 
::is scalar do {to_url_param "a b"}, "a+b", 'to_url_param "a b" # => a+b';

::is_deeply scalar do {[map to_url_param, "a b", "🦁"]}, scalar do {[qw/a+b %1F981/]}, '[map to_url_param, "a b", "🦁"] # --> [qw/a+b %1F981/]';

# 
# ## to_url_params (;$hash_ref)
# 
# Generates the search part of the url.
# 
done_testing; }; subtest 'to_url_params (;$hash_ref)' => sub { 
::is scalar do {to_url_params {a => 1, b => [[1,2],3]}}, "a&b[][]&b[][]=2&b[]=3", 'to_url_params {a => 1, b => [[1,2],3]}  # => a&b[][]&b[][]=2&b[]=3';

# 
# 1. Keys with undef values not stringify.
# 1. Empty value is empty.
# 1. `1` value stringify key only.
# 1. Keys stringify in alfabet order.
# 

::is scalar do {to_url_params {k => "", n => undef, f => 1}}, "f&k=", 'to_url_params {k => "", n => undef, f => 1}  # => f&k=';

# 
# ## parse_url (;$url)
# 
# Parses and normalizes url.
# 
done_testing; }; subtest 'parse_url (;$url)' => sub { 
my $res = {
    dom    => "off",
    domen  => "off",
    link   => "off://off/",
    orig   => "",
    proto  => "off",
};

::is_deeply scalar do {parse_url ""}, scalar do {$res}, 'parse_url ""    # --> $res';

local $_ = ["/page", "https://www.main.com/pager/mix"];
$res = {
    proto  => "https",
    dom    => "www.main.com",
    domen  => "main.com",
    link   => "https://www.main.com/page",
    path   => "/page",
    dir    => "/page/",
    orig   => "/page",
};

::is_deeply scalar do {parse_url}, scalar do {$res}, 'parse_url    # --> $res';

$res = {
    proto  => "https",
    user   => "user",
    pass   => "pass",
    dom    => "www.x.test",
    domen  => "x.test",
    path   => "/path",
    dir    => "/path/",
    query  => "x=10&y=20",
    hash   => "hash",
    link   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
    orig   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
};
::is_deeply scalar do {parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'}, scalar do {$res}, 'parse_url \'https://user:pass@www.x.test/path?x=10&y=20#hash\'  # --> $res';

# 
# See also `URL::XS`.
# 
# ## normalize_url (;$url)
# 
# Normalizes url.
# 
done_testing; }; subtest 'normalize_url (;$url)' => sub { 
::is scalar do {normalize_url ""}, "off://off", 'normalize_url ""  # => off://off';
::is scalar do {normalize_url "www.fix.com"}, "off://off/www.fix.com", 'normalize_url "www.fix.com"  # => off://off/www.fix.com';
::is scalar do {normalize_url ":"}, "off://off/:", 'normalize_url ":"  # => off://off/:';
::is scalar do {normalize_url '@'}, "off://off/@", 'normalize_url \'@\'  # => off://off/@';
::is scalar do {normalize_url "/"}, "off://off", 'normalize_url "/"  # => off://off';
::is scalar do {normalize_url "//"}, "off://off", 'normalize_url "//" # => off://off';
::is scalar do {normalize_url "?"}, "off://off", 'normalize_url "?"  # => off://off';
::is scalar do {normalize_url "#"}, "off://off", 'normalize_url "#"  # => off://off';

::is scalar do {normalize_url "dir/file", "http://www.load.er/fix/mix"}, "http://load.er/dir/file", 'normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file';
::is scalar do {normalize_url "?x", "http://load.er/fix/mix?y=6"}, "http://load.er/fix/mix/bp/file", 'normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix/bp/file';
die "===== OK! =====";

# 
# See also `URI::URL`.
# 
# ## surf (\[$method], $url, \[$data], %params)
# 
# Send request by LWP::UserAgent and adapt response.
# 
# `@params` maybe:
# 
# * `query` - add query params to `$url`.
# * `json` - body request set in json format. Add header `Content-Type: application/json; charset=utf-8`.
# * `form` - body request set in url params format. Add header `Content-Type: application/x-www-form-urlencoded`.
# * `headers` - add headers. If `header` is array ref, then add in the order specified. If `header` is hash ref, then add in the alphabet order.
# * `cookies` - add cookies. Same as: `cookies => {go => "xyz", session => ["abcd", path => "/page"]}`.
# * `response` - returns response (as HTTP::Response) by this reference.
# 
done_testing; }; subtest 'surf (\[$method], $url, \[$data], %params)' => sub { 
my $req = "
";

# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;

::is scalar do {$request->as_string}, scalar do{$req}, '    $request->as_string # -> $req';

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
::is scalar do {$res}, scalar do{.3}, '$res # -> .3';

# 
# ## head (;$)
# 
# Check resurce in internet. Returns `1` if exists resurce in internet, otherwice returns `""`.
# 
# ## get (;$url)
# 
# Get content from resurce in internet.
# 
# ## post (;$url)
# 
# Add content resurce in internet.
# 
# ## put (;$url)
# 
# Create or update resurce in internet.
# 
# ## patch (;$url)
# 
# Set attributes on resurce in internet.
# 
# ## del (;$url)
# 
# Delete resurce in internet.
# 
# ## chat_message ($chat_id, $message)
# 
# Sends a message to a telegram chat.
# 
done_testing; }; subtest 'chat_message ($chat_id, $message)' => sub { 
::is scalar do {chat_message "ABCD", "hi!"}, "ok", 'chat_message "ABCD", "hi!"  # => ok';

# 
# ## bot_message (;$message)
# 
# Sends a message to a telegram bot.
# 
done_testing; }; subtest 'bot_message (;$message)' => sub { 
::is scalar do {bot_message "hi!"}, "ok", 'bot_message "hi!" # => ok';

# 
# ## tech_message (;$message)
# 
# Sends a message to a technical telegram channel.
# 
done_testing; }; subtest 'tech_message (;$message)' => sub { 
::is scalar do {tech_message "hi!"}, "ok", 'tech_message "hi!" # => ok';

# 
# ## bot_update ()
# 
# Receives the latest messages sent to the bot.
# 
done_testing; }; subtest 'bot_update ()' => sub { 
::is_deeply scalar do {bot_update}, scalar do { }, 'bot_update  # -->';

# 
# # SEE ALSO
# 
# * LWP::Simple
# * LWP::Simple::Post
# * HTTP::Request::Common
# * WWW::Mechanize
# * [An article about sending an HTTP request to a server](https://habr.com/ru/articles/63432/)
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
