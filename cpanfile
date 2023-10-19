on 'develop' => sub {
    requires 'Minilla', 'v3.1.19';
    requires 'Liveman', '1.0';
};

on 'test' => sub {
	requires 'Test::More', '0.98';
};

requires 'common::sense';
requires 'JSON::XS', '4.03';
requires 'List::Util';
requires 'LWP::UserAgent', '6.72';
requires 'HTTP::Cookies';
