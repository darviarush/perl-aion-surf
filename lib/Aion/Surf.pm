package Aion::Surf;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.0-prealpha";

require Exporter;
our @EXPORT = our @EXPORT_OK = grep {
	*{$Aion::Surf::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Surf::;

sub escape_url_param($) {
	my ($param) = @_;
	$param =~ s/[&=?#+\s]/$& eq " "? "+": sprintf "%%%02X", ord $&/ge;
	$param
}

sub escape_url_params($) {
	my ($param) = @_;

	join "&",
		map { my $val = $param->{$_};
			ref $val eq "ARRAY"? (
				(grep /^[^,]+\z/, @$val) == @$val? "$_=" . join(",", map escape_url_param($_), @$val):
				do { my $key = $_; map "${key}[]=${\escape_url_param($_)}", @$val }
			):
			$val eq 1? "$_":
			"$_=" . escape_url_param($val) 
		}
		grep {defined $param->{$_}} sort keys %$param
}

sub json() {
	require JSON::XS;
	JSON::XS->new->allow_nonref->indent(1)->space_after(1)->canonical(1)
}

sub to_json($) {
	json->encode($_[0])
}

sub from_json($) {
	json->decode($_[0])
}

my %HTML_SIM = qw/< &lt; > &gt; & &amp; ' &#39; " &quot;/;
sub to_html (@) {
	local $_ = join "", @_;
	s/[<>&\'\"]/$HTML_SIM{$&}/ge;
	$_
}

# вырезает из html-я все теги и переводит энтишены в символы
sub from_html ($) {
	require html;
	html::html2text($_[0])
}

# вырезает из html-я опасные теги
sub safe_html ($;$) {
	require html;
	html::safe4html(@_)
}

# Парсит и нормализует url
sub parse_url($;$) {
	my ($link, $onpage) = @_;

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
sub normalize_url($;$) {
	my ($link, $onpage) = @_;
	my $x = ref $link? $link: parse_url $link, $onpage;
	join "", $x->{proto}, "://", $x->{domen}, $x->{path}, exists $x->{query}? ("?", $x->{query}): (), exists $x->{hash}? ("#", $x->{hash}): ();
}

our $ua;
our $LAST_REQUEST = Time::HiRes::time();
sub _www_sleep() { Time::HiRes::sleep(rand + .5) if Time::HiRes::time() - $LAST_REQUEST < 2; $LAST_REQUEST = Time::HiRes::time() }

sub _lwp_simple {
	require LWP::UserAgent;
	require HTTP::Date;
	require HTTP::Status;
	$ua = LWP::UserAgent->new;
	$ua->agent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 OPR/92.0.0.0");
	#$ua->env_proxy;
	$ua->timeout($main_config::www_timeout // 10);
	$ua->local_address($main_config::www_from_ip) if $main_config::www_from_ip;
	*www_get = \&_www_get;
	*www_head = \&_www_head;
	*www = \&_www;
}

sub www_get($;$) { _lwp_simple(); goto &_www_get }
sub www_head($) { _lwp_simple(); goto &_www_head }
sub www(@) { _lwp_simple(); goto &_www }
 
sub _www_get($;$) {
	_www_sleep;
	
	$_[1] = my $response = $ua->get($_[0]);
	my $data;

	$data = $response->decoded_content if $response->is_success;

	$data
}

sub _www_head($) {
	_www_sleep;
	my $request = HTTP::Request->new(HEAD => @_);
	my $response = $ua->request($request);
 
	if ($response->is_success) {
		return $response unless wantarray;
		return
			scalar $response->header('Content-Type'),
			scalar $response->header('Content-Length'),
			HTTP::Date::str2time($response->header('Last-Modified')),
			HTTP::Date::str2time($response->header('Expires')),
			scalar $response->header('Server'),
		;
	}
	wantarray? (): undef;
}

sub _www(@) {
	_www_sleep;
	my ($method, $url, %set) = @_;
	
	my $request = HTTP::Request->new(uc $method => $url);
	
	my $json = delete $set{json};
	if(defined $json) {
		$request->header('Content-Type' => 'application/json; charset=utf-8');
		$json = to_json($json);
		utf8::encode($json) if utf8::is_utf8($json);
		$request->content($json);
	}

	my $form = delete $set{form};
	if(defined $form) {
		require URI::Escape;
		$request->header('Content-Type' => 'application/x-www-form-urlencoded');
		$form = join "&", pairmap { join "=", URI::Escape::uri_escape_utf8($a) => URI::Escape::uri_escape_utf8($b) } (ref $form eq "HASH"? (map { ($_ => $form->{$_}) } sort keys %$form): @$form);
		$request->content($form);
	}
	
	if(my $headers = delete $set{headers}) {
		if(ref $headers eq 'HASH') {
			$request->header($_, $headers->{$_}) for sort keys %$headers;
		} else {
			pairmap { $request->header($a, $b); () } @$headers;
		}
	}
	
	my $response_set = delete $set{response};
	
	die "Неизвестные ключи: " . join ", ", keys %set if keys %set;
	
	my $response = $ua->request($request);
	$$response_set = $response if ref $response_set;
	
	#p $response if !$response->is_success;
	
	my $data = $response->decoded_content;
	eval { $data = from_json($data) } if $data =~ m!^\{!;

	$data
}

# Отправляет сообщение телеграм
sub chat_message($$) {
	my ($chat_id, $message) = @_;
	
	my $ok = www POST => "https://api.telegram.org/bot$main_config::telegram_bot_token/sendMessage", response => \my $response, json => {
		chat_id => $chat_id,
		text => $message,
		disable_web_page_preview => 1,
		parse_mode => 'Html',
	};
	
	p($response), p($ok), die $ok->{description} if !$ok->{ok};
	
	$ok
}

# Отправляет сообщение в телеграм-бот
sub bot_message($) { chat_message $main_config::telegram_bot_chat_id, $_[0] }
# Отправляет сообщение в технический телеграм канал
sub tech_message($) { chat_message $main_config::telegram_tech_chat_id, $_[0] }


# Получает последние сообщения отправленные боту
sub bot_update() {
	my ($message) = @_;
	
	my @updates;
	
	for(my $offset = 0;;) {
	
		my $ok = www POST => "https://api.telegram.org/bot$main_config::telegram_bot_token/getUpdates", json => {
			offset => $offset,
		};
		
		die $ok->{description} if !$ok->{ok};
		
		my $result = $ok->{result};
		return \@updates if !@$result;
		
		push @updates, map $_->{message}, grep $_->{message}, @$result;
		
		$offset = $result->[$#$result]{update_id} + 1;
	}
	
	return \@updates;
}

1;
