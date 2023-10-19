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
use Test::Mock::LWP;

::is_deeply scalar do {get "http://api.xyz"}, scalar do {[]}, 'get "http://api.xyz"  # --> []';

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
}';

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

::is_deeply scalar do {[map to_url_param, "a b", "🦁"]}, scalar do {[qw/a+b %/]}, '[map to_url_param, "a b", "🦁"] # --> [qw/a+b %/]';

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
::is_deeply scalar do {parse_url ""}, scalar do {{}}, 'parse_url ""    # --> {}';

local $_ = ["/page", "https://main.com/pager/mix"];

# 
# See also `URL::XS`.
# 
# ## normalize_url (;$url)
# 
# Normalizes url.
# 
done_testing; }; subtest 'normalize_url (;$url)' => sub { 
::is scalar do {normalize_url ""}, scalar do{.3}, 'normalize_url ""  # -> .3';

# 
# See also `URI::URL`.
# 
# ## surf (@params)
# 
# Send request by LWP::UserAgent and adapt response.
# 
done_testing; }; subtest 'surf (@params)' => sub { 
::is scalar do {surf "https://ya.ru", cookie => {}}, scalar do{.3}, 'surf "https://ya.ru", cookie => {}  # -> .3';

# 
# ## head (;$)
# 
# Check resurce in internet. Returns `HTTP::Request` if exists resurce in internet, otherwice returns `undef`.
# 
done_testing; }; subtest 'head (;$)' => sub { 
::is scalar do {head ""}, scalar do{.3}, 'head "" # -> .3';

# 
# ## get (;$url)
# 
# Get resurce in internet.
# 
done_testing; }; subtest 'get (;$url)' => sub { 
::is scalar do {get "http://127.0.0.1/"}, scalar do{.3}, 'get "http://127.0.0.1/" # -> .3';

# 
# ## post (;$url)
# 
# Add resurce in internet.
# 
done_testing; }; subtest 'post (;$url)' => sub { 
::is scalar do {post ["", {a => 1, b => 2}]}, scalar do{.3}, 'post ["", {a => 1, b => 2}] # -> .3';

# 
# ## put (;$url)
# 
# Create or update resurce in internet.
# 
done_testing; }; subtest 'put (;$url)' => sub { 
::is scalar do {put}, scalar do{.3}, 'put  # -> .3';

# 
# ## patch (;$url)
# 
# Set attributes on resurce in internet.
# 
done_testing; }; subtest 'patch (;$url)' => sub { 
my $aion_surf = Aion::Surf->new;
::is scalar do {$aion_surf->patch}, scalar do{.3}, '$aion_surf->patch  # -> .3';

# 
# ## del (;$url)
# 
# Delete resurce in internet.
# 
done_testing; }; subtest 'del (;$url)' => sub { 
::is scalar do {del ""}, scalar do{.3}, 'del "" # -> .3';

# 
# ## chat_message ($chat_id, $message)
# 
# Sends a message to a telegram chat.
# 
done_testing; }; subtest 'chat_message ($chat_id, $message)' => sub { 
::is scalar do {chat_message "ABCD", "hi!"}, scalar do{.3}, 'chat_message "ABCD", "hi!"  # -> .3';

# 
# ## bot_message (;$message)
# 
# Sends a message to a telegram bot.
# 
done_testing; }; subtest 'bot_message (;$message)' => sub { 
::is scalar do {bot_message "hi!"}, scalar do{.3}, 'bot_message "hi!" # -> .3';

# 
# ## tech_message (;$message)
# 
# Sends a message to a technical telegram channel.
# 
done_testing; }; subtest 'tech_message (;$message)' => sub { 
::is scalar do {tech_message "hi!"}, scalar do{.3}, 'tech_message "hi!" # -> .3';

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
