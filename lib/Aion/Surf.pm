package Aion::Surf;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.0-prealpha";

use JSON::XS qw//;
use List::Util qw/pairmap/;
use LWP::UserAgent qw//;
use HTTP::Cookies qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Surf::{$_} eq "GLOB"
		&& *{$Aion::Surf::{$_}}{CODE}
			&& !/^(_|(NaN|import)\z)/n
} keys %Aion::Surf::;

#@category json

# Настраиваем json
our $JSON = JSON::XS->new->allow_nonref->indent(1)->space_after(1)->canonical(1);

# В json
sub to_json(;$) {
	$JSON->encode(@_ == 0? $_: @_)
}

# Из json
sub from_json(;$) {
	$JSON->decode(@_ == 0? $_: @_)
}

#@category escape url

use constant UNSAFE_RFC3986 => qr/[^A-Za-z0-9\-\._~]/;

sub to_url_param(;$) {
	my ($param) = @_ == 0? $_: @_;
	$param =~ s/${\ UNSAFE_RFC3986}/$& eq " "? "+": sprintf "%%%02X", ord $&/age;
	$param
}

sub _escape_url_params {
	my ($key, $param) = @_;

	!defined($param)? ():
	$param eq 1? $key:
	ref $param eq "HASH"? do {
		join "&", map _escape_url_params("${key}[$_]", $param->{$_}), sort keys %$param
	}:
	ref $param eq "ARRAY"? do {
		join "&", map _escape_url_params("${key}[]", $_), @$param
	}:
	"$key=${\ to_url_param($param)}"
}

sub to_url_params(;$) {
	my ($param) = @_ == 0? $_: @_;

	join "&", map _escape_url_params($_, $param->{$_}), sort keys %$param
}

# #@see https://habr.com/ru/articles/63432/
# # В multipart/form-data
# sub to_multipart(;$) {
# 	my ($param) = @_ == 0? $_: @_;
# 	$param =~ s/[&=?#+\s]/$& eq " "? "+": sprintf "%%%02X", ord $&/ge;
# 	$param
# }

#@category parse url

# Парсит и нормализует url
sub parse_url(;$) {
	my ($link) = @_ == 0? $_: @_;
	my $onpage;
	($link, $onpage) = @$link if ref $link eq "ARRAY";
	$onpage //= "off://off";
	my $orig = $link;

	# Если ссылка не абсолютная — подставляем протокол
	if($link =~ m!^//!) { $link = $onpage =~ m!^(\w+:)//[^/?#]!? "$1$link": die "\$onpage — не url, а „${onpage}”" }
	elsif($link =~ m!^/!) { # Подставляем протокол и домен
		$link = $onpage =~ m!^\w+://[^/?#]+!? "$&$link": die "\$onpage — не url, а „${onpage}”";
	} elsif($link !~ m!^\w+://!) { # Подставляем после директории
		$link = $onpage =~ m!^\w+://[^/?#]+(/([^?#]*/)?)?!? $& . do {$& !~ m!/\z!? "/": ""} . $link: die "\$onpage — не url, а „${onpage}”";
	}

	$link =~ m!^
		(?<proto> \w+ ) ://
		(?<dom> [^/?\#]+ )
		(  / (?<path>  [^?\#]* ) )?
		( \? (?<query> [^\#]*  ) )?
		( \# (?<hash>  .*	  ) )?
	\z!xn || die "Ссылка „$link” — не url!";

	my $x = {%+, orig => $orig, link => $link};

	# нормализуем
	$x->{proto} = lc $x->{proto};
	$x->{dom} = lc $x->{dom};
	$x->{domen} = $x->{dom} =~ s/^www\.//r;

	my @path = split m!/!, $x->{path}; my @p;

	for my $p (@path) {
		if($p eq ".") {}
		elsif($p eq "..") {
			#@p or die "Выход за пределы пути";
			pop @p;
		}
		else { push @p, $p }
	}

	@p = grep { $_ ne "" } @p;

	if(@p) {
		$x->{path} = join "/", "", @p;
		if($x->{path} =~ m![^/]*\.[^/]*\z!) {
			$x->{dir} = $`;
			$x->{file} = $&;
		} else {
			$x->{path} .= "/";
			$x->{dir} = $x->{path};
		}
	} else { delete $x->{path} }

	return $x;
}

# Нормализует url
sub normalize_url(;$) {
	my ($link) = @_ == 0? $_: @_;
	my $onpage;
	($link, $onpage) = @$link if ref $link eq "ARRAY";
	my $x = ref $link? $link: parse_url $link, $onpage;
	join "", $x->{proto}, "://", $x->{domen}, $x->{path}, exists $x->{query}? ("?", $x->{query}): (), exists $x->{hash}? ("#", $x->{hash}): ();
}

#@category surf

use config TIMEOUT => 10;
use config FROM_IP => undef;
use config AGENT => q{Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 OPR/92.0.0.0};

our $ua = LWP::UserAgent->new;
$ua->agent(AGENT);
#$ua->env_proxy;
$ua->timeout(TIMEOUT);
$ua->local_address(FROM_IP) if FROM_IP;
$ua->cookie_jar(HTTP::Cookies->new);

# Между вызовами делаем случайный интервал (для граббинга - чтобы не быть заблокированным за автоматические обращения)
our $LAST_REQUEST = Time::HiRes::time();
sub _sleep() { Time::HiRes::sleep(rand + .5) if Time::HiRes::time() - $LAST_REQUEST < 2; $LAST_REQUEST = Time::HiRes::time() }

sub surf(@) {
	_sleep;

	my $method = $_[0] =~ /^(\w+)\z/ ? shift: "GET";
	my $url = shift;
	my $headers;
	my $data = ref $_[0]? shift: undef;
	$headers = $data, undef $data if $method =~ /^(GET|HEAD)\z/n;

	my %set = @_;

	my $query = delete $set{query};
	if(defined $query) {
		$url = join "", $url, $url =~ /\?/ ? "&": "?", escape_url_params $query;
	}

	my $request = HTTP::Request->new($method => $url);

	# Устанавливаем данные
	my $json = delete $set{json};
	if(defined $json) {
		$request->header('Content-Type' => 'application/json; charset=utf-8');
		$json = to_json($json);
		utf8::encode($json) if utf8::is_utf8($json);
		$request->content($json);
	}

	my $form = delete $set{form};
	if(defined $form) {
		$request->header('Content-Type' => 'application/x-www-form-urlencoded');
		$request->content(escape_url_params $form);
	}

	if($headers = delete($set{headers}) // $headers) {
		if(ref $headers eq 'HASH') {
			$request->header($_, $headers->{$_}) for sort keys %$headers;
		} else {
			for my ($key, $val) (@$headers) {
				$request->header($key, $val);
			}
		}
	}

	if(my $cookie_href = delete $set{cookie}) {
		my $jar = $ua->cookie_jar;
		my $url_href = parse_url $url;
		my $domain = $url_href->{dom};
		$domain = "localhost.local" if $domain eq "localhost";

		for my $key (sort keys %$cookie_href) {

			my $av;
			my $val = $cookie_href->{$key};
			$av = $val, $val = shift @$av, $av = {@$av} if ref $val;

			$jar->set_cookie(
				$a->{version},
				$key => $val,
				$av->{path} // "/",
				$av->{domain} // $domain,
				$av->{port},
				$av->{path_spec},
				$av->{secure},
				$av->{maxage},
				$av->{discard},
				$av
			);
		}
	}

	my $response_set = delete $set{response};

	die "Unknown keys: " . join ", ", keys %set if keys %set;

	my $response = $ua->request($request);
	$$response_set = $response if ref $response_set;

	return $response->is_success? 1: "" if $method eq "HEAD";

	my $data = $response->decoded_content;
	eval { $data = from_json($data) } if $data =~ m!^\{!;

	$data
}

sub head (;$) { my $x = @_ == 0? shift: $_; surf HEAD   => (ref $x? @{$x}: $x) }
sub get  (;$) { my $x = @_ == 0? shift: $_; surf GET    => (ref $x? @{$x}: $x) }
sub post (;$) { my $x = @_ == 0? shift: $_; surf POST   => (ref $x? @{$x}: $x) }
sub put  (;$) { my $x = @_ == 0? shift: $_; surf PUT    => (ref $x? @{$x}: $x) }
sub patch(;$) { my $x = @_ == 0? shift: $_; surf PATCH  => (ref $x? @{$x}: $x) }
sub del  (;$) { my $x = @_ == 0? shift: $_; surf DELETE => (ref $x? @{$x}: $x) }


use config TELEGRAM_BOT_TOKEN => undef;

# Отправляет сообщение телеграм
sub chat_message($$) {
	my ($chat_id, $message) = @_;

	my $ok = post ["https://api.telegram.org/bot${\ TELEGRAM_BOT_TOKEN}/sendMessage", response => \my $response, json => {
		chat_id => $chat_id,
		text => $message,
		disable_web_page_preview => 1,
		parse_mode => 'Html',
	}];

	p($response), p($ok), die $ok->{description} if !$ok->{ok};

	$ok
}


use config TELEGRAM_BOT_CHAT_ID => undef;
use config TELEGRAM_BOT_TECH_ID => undef;

# Отправляет сообщение в телеграм-бот
sub bot_message(;$) { chat_message TELEGRAM_BOT_CHAT_ID, @_ == 0? $_: $_[0] }
# Отправляет сообщение в технический телеграм канал
sub tech_message(;$) { chat_message TELEGRAM_BOT_TECH_ID, @_ == 0? $_: $_[0] }


# Получает последние сообщения отправленные боту
sub bot_update() {
	my @updates;

	for(my $offset = 0;;) {

		my $ok = post ["https://api.telegram.org/bot${\ TELEGRAM_BOT_TOKEN}/getUpdates", json => {
			offset => $offset,
		}];

		die $ok->{description} if !$ok->{ok};

		my $result = $ok->{result};
		return \@updates if !@$result;

		push @updates, map $_->{message}, grep $_->{message}, @$result;

		$offset = $result->[$#$result]{update_id} + 1;
	}

	return \@updates;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Surf - surfing by internet

=head1 VERSION

0.0.0-prealpha

=head1 SYNOPSIS

	use Aion::Surf;
	use Test::Mock::LWP;
	
	get "http://api.xyz"  # --> []

=head1 DESCRIPTION

Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.

=head1 SUBROUTINES

=head2 to_json ($data)

Translate data to json format.

	my $data = {
	    a => 10,
	};
	
	my $result = '{
	    "a": 10
	}';
	
	to_json $data # -> $result
	
	local $_ = $data;
	to_json # -> $result

=head2 from_json ($string)

Parse string in json format to perl structure.

	from_json '{"a": 10}' # --> {a => 10}

=head2 to_url_param (;$scalar)

Escape scalar to part of url search.

	to_url_param "a b" # => a+b
	
	[map to_url_param, "a b", "🦁"] # --> [qw/a+b %/]

=head2 to_url_params (;$hash_ref)

Generates the search part of the url.

	to_url_params {a => 1, b => [[1,2],3]}  # => a&b[][]&b[][]=2&b[]=3

=over

=item 1. Keys with undef values not stringify.

=item 2. Empty value is empty.

=item 3. C<1> value stringify key only.

=item 4. Keys stringify in alfabet order.

=back

	to_url_params {k => "", n => undef, f => 1}  # => f&k=

=head2 parse_url (;$url)

Parses and normalizes url.

	parse_url ""    # --> {}
	
	local $_ = ["/page", "https://main.com/pager/mix"];

See also C<URL::XS>.

=head2 normalize_url (;$url)

Normalizes url.

	normalize_url ""  # -> .3

See also C<URI::URL>.

=head2 surf (@params)

Send request by LWP::UserAgent and adapt response.

	surf "https://ya.ru", cookie => {}  # -> .3

=head2 head (;$)

Check resurce in internet. Returns CL<HTTP::Request> if exists resurce in internet, otherwice returns C<undef>.

	head "" # -> .3

=head2 get (;$url)

Get resurce in internet.

	get "http://127.0.0.1/" # -> .3

=head2 post (;$url)

Add resurce in internet.

	post ["", {a => 1, b => 2}] # -> .3

=head2 put (;$url)

Create or update resurce in internet.

	put  # -> .3

=head2 patch (;$url)

Set attributes on resurce in internet.

	my $aion_surf = Aion::Surf->new;
	$aion_surf->patch  # -> .3

=head2 del (;$url)

Delete resurce in internet.

	del "" # -> .3

=head2 chat_message ($chat_id, $message)

Sends a message to a telegram chat.

	chat_message "ABCD", "hi!"  # -> .3

=head2 bot_message (;$message)

Sends a message to a telegram bot.

	bot_message "hi!" # -> .3

=head2 tech_message (;$message)

Sends a message to a technical telegram channel.

	tech_message "hi!" # -> .3

=head2 bot_update ()

Receives the latest messages sent to the bot.

	bot_update  # --> 

=head1 SEE ALSO

=over

=item * LWP::Simple

=item * LWP::Simple::Post

=item * HTTP::Request::Common

=item * WWW::Mechanize

=item * LLL<https://habr.com/ru/articles/63432/>

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
