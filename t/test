#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib qw/lib/;

use Test::More tests => 78;
use Mojo::ByteStream 'b';
use Data::Dumper;

use_ok("Net::OAuth::All");

diag "version_autodetect";

is(Net::OAuth::All::version_autodetect({
	consumer_key      => 'gjnj3n8848hkdsdksknskjnu48',
	consumer_secret   => 'gjnj3n8848hkdsdksknskjnu48ffgdsknfjkndngjbu43h',
}), '1.0', 'version_autodetect return 1.0');

is(Net::OAuth::All::version_autodetect({
	consumer_key      => 'gjnj3n8848hkdsdksknskjnu48',
	consumer_secret   => 'gjnj3n8848hkdsdksknskjnu48ffgdsknfjkndngjbu43h',
	verifier          => 'test',
}), '1.0A', 'version_autodetect return 1.0A');

is(Net::OAuth::All::version_autodetect({
	type              => 'web_server',
	client_id         => '999999999999999',
}), '2.0', 'version_autodetect return 2.0');


my $oauth = eval {Net::OAuth::All->new()};
diag("Without config");
isnt($@, '', "Config ERROR. ".$@);


diag("------OAuth 1.0A");
my $config = {
	consumer_key      => 'consumer_key',
	consumer_secret   => 'consumer_secret',
	signature_method  => 'HMAC-SHA1',
	request_token_url => 'https://friendfeed.com/request_token',
	callback          => 'http://example.com/friendfeed/',
	authorization_url => 'https://friendfeed.com/authorize',
	access_token_url  => 'https://friendfeed.com/access_token',
	protected_resource_url => 'http://friendfeed-api.com/v2/feed/me',
	extra_params    => {
		scope => 'https://www-opensocial.googleusercontent.com/api/people/@me',
	},
};
$oauth = eval {Net::OAuth::All->new(%$config)};
ok(!$@, $@ || "Successfully creation Net::OAuth::All object");

diag "------------request_token REQUEST";
eval {$oauth->request('request_token')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'request_token_url'}, 'Construct Request URL');

my $params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/consumer_key signature_method timestamp nonce callback/),
	(%{ $config->{extra_params} }),
};
$params = [sort map { b($_)->url_escape."=".b($params->{$_})->url_escape } keys %$params];
is_deeply(
	[$oauth->params('delete' => ['signature'])],
	$params,
	'Request Parameters For Signature'
);
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');
is($oauth->signature_base_string, join('&', 'GET', map {b($oauth->$_)->url_escape} qw/normalized_request_url normalized_message_parameters/), "Signature Base String");

is($oauth->signature_key, b($oauth->{'consumer_secret'})->url_escape."&".(b($oauth->{'token_secret'})->url_escape || ''), "check key for signing HMAC_SHA1 method");
is($oauth->signature, b( pack('H*', b($oauth->signature_base_string)->hmac_sha1_sum($oauth->signature_key)->to_string) )->b64_encode('')->to_string, "Signature");

diag ">>>>>>>>>>>>>>>UTILS";
$oauth->via('POST');
is($oauth->via, 'POST', "test via");
is(ref $oauth->via('GET'), 'Net::OAuth::All', "test via");


$params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/consumer_key signature_method signature timestamp nonce callback/),
	(%{ $config->{extra_params} }),
};
is_deeply(
	$oauth->to_hash,
	$params,
	'to HASH'
);
$oauth->put_extra(
	'extra1' => 1,
	'extra2' => 2,
);
$params = $oauth->extra;
ok($params->{'extra1'} == 1 && $params->{'extra2'} == 2, "put extra");
is(
	$oauth->to_post_body, 
	'',
	, "to POST BODY if GET"
);
$params = $oauth->to_hash;
is_deeply(
	[$oauth->params(quote => '"', no_extra => 1)],
	[
		sort
		map  {join '=', $_, '"'.b( $params->{$_} )->url_escape.'"'}
		grep {!($config->{'extra_params'} || {})->{$_}}
		keys %$params
	],
	'no_extra and quote'
);
is(
	$oauth->to_header('Net::OAuth::All (Perl)'), 
	join( ',', 'OAuth realm="Net::OAuth::All (Perl)"',  $oauth->params(quote => '"', no_extra => 1) ),
	, "to HEADER"
);

$oauth->from_hash(oauth_test1 => 'test1', test2 => 'test2');
ok($oauth->{'test1'} eq 'test1' && $oauth->{'test2'} eq 'test2', "from HASH");

delete $oauth->{'test1'};
delete $oauth->{'extra_params'}->{'test2'};

$oauth->from_hash(oauth_token => 'token', oauth_token_secret => 'token_secret');
ok($oauth->token eq 'token' && $oauth->token_secret eq 'token_secret', "token and token_secret");

$oauth->from_post_body(join '&', "oauth_test_3=".b("test//&")->url_escape, "test_4=".b("test4123 //&")->url_escape);
ok($oauth->{'test_3'} eq 'test//&' && $oauth->{'test_4'} eq "test4123 //&", "from POST BODY");

delete $oauth->{'test_3'};
delete $oauth->{'extra_params'}->{'test_4'};

is(
	$oauth->to_url,
	$oauth->url.'?'.join('&', $oauth->params),
	, "to URL"
);

$oauth->via('POST');

is(
	$oauth->to_post_body, 
	join( '&', $oauth->params(extra => 1)),
	, "to POST BODY if POST"
);
$oauth->via('GET');


diag "------------RESPONSE";
$oauth->response;
ok(!defined($oauth->token) && !defined($oauth->token_secret), "clean params in response");

diag "------------authorization REQUEST";
eval {$oauth->request('authorization', 'oauth_token' => 'cgfgtoken', 'oauth_token_secret' => 'fhknkallopore')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'authorization_url'}, 'Construct Request URL');

$params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/token callback/),
	(%{ $config->{extra_params} }),
};
$params = [sort map { b($_)->url_escape."=".b($params->{$_})->url_escape } keys %$params];
is_deeply(
	[$oauth->params],
	$params,
	'Request Parameters For Signature'
);
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');
is($oauth->signature_base_string, join('&', 'GET', map {b($oauth->$_)->url_escape} qw/normalized_request_url normalized_message_parameters/), "Signature Base String");

is($oauth->signature_key, b($oauth->{'consumer_secret'})->url_escape."&".(b($oauth->{'token_secret'})->url_escape || ''), "check key for signing HMAC_SHA1 method");
is($oauth->signature, b( pack('H*', b($oauth->signature_base_string)->hmac_sha1_sum($oauth->signature_key)->to_string) )->b64_encode('')->to_string, "Signature");

is(
	$oauth->to_url,
	$oauth->url.'?'.join('&', $oauth->params),
	, "to URL"
);



diag "------------access_token REQUEST";
$oauth = eval {Net::OAuth::All->new(
	%$config,
	'token'        => 'rttyyjjkjk',#request_token saved before
	'token_secret' => 'dddsdserrttttsdsss',#request_token_secret saved before
	'verifier'     => 'fghgqqq',#param from provider in callback
)};
ok(!$@, $@ || "Successfully creation Net::OAuth::All object");

eval {$oauth->request('access_token')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'access_token_url'}, 'Construct Request URL');

$params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/consumer_key signature_method token timestamp nonce verifier/),
	(%{ $config->{extra_params} }),
};
$params = [sort map { b($_)->url_escape."=".b($params->{$_})->url_escape } keys %$params];
is_deeply(
	[$oauth->params(delete => ['signature'])],
	$params,
	'Request Parameters For Signature'
);
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');
is($oauth->signature_base_string, join('&', 'GET', map {b($oauth->$_)->url_escape} qw/normalized_request_url normalized_message_parameters/), "Signature Base String");

is($oauth->signature_key, b($oauth->{'consumer_secret'})->url_escape."&".(b($oauth->{'token_secret'})->url_escape || ''), "check key for signing HMAC_SHA1 method");
is($oauth->signature, b( pack('H*', b($oauth->signature_base_string)->hmac_sha1_sum($oauth->signature_key)->to_string) )->b64_encode('')->to_string, "Signature");

is(
	$oauth->to_url,
	$oauth->url.'?'.join('&', $oauth->params),
	, "to URL"
);


diag "------------protected_resource REQUEST";
$oauth->via('POST');
$oauth->response->from_post_body(join '&', "oauth_token=kjknhnjsiiwinw", "oauth_token_secret=lkmmmooppnjnqwuuuu5i5n5555");
ok($oauth->token eq 'kjknhnjsiiwinw' && $oauth->token_secret eq "lkmmmooppnjnqwuuuu5i5n5555", "from POST BODY");

eval {$oauth->request('protected_resource')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'protected_resource_url'}, 'Construct Request URL');

$params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/consumer_key signature_method token timestamp nonce/),
	(%{ $config->{extra_params} }),
};
$params = [sort map { b($_)->url_escape."=".b($params->{$_})->url_escape } keys %$params];
is_deeply(
	[$oauth->params(delete => ['signature'])],
	$params,
	'Request Parameters For Signature'
);
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');
is($oauth->signature_base_string, join('&', 'POST', map {b($oauth->$_)->url_escape} qw/normalized_request_url normalized_message_parameters/), "Signature Base String");

is($oauth->signature_key, b($oauth->{'consumer_secret'})->url_escape."&".(b($oauth->{'token_secret'})->url_escape || ''), "check key for signing HMAC_SHA1 method");
is($oauth->signature, b( pack('H*', b($oauth->signature_base_string)->hmac_sha1_sum($oauth->signature_key)->to_string) )->b64_encode('')->to_string, "Signature");

is(
	$oauth->to_post_body, 
	join( '&', $oauth->params(extra => 1)),
	, "to POST BODY"
);
is(
	$oauth->to_header('Net::OAuth::All (Perl)'), 
	join( ',', 'OAuth realm="Net::OAuth::All (Perl)"',  $oauth->params(quote => '"', no_extra => 1) ),
	, "to HEADER"
);


diag "------------protected_resource custom REQUEST";
$oauth->response->from_post_body(join '&', "oauth_token=kjknhnjsiiwinw", "oauth_token_secret=lkmmmooppnjnqwuuuu5i5n5555");
ok($oauth->token eq 'kjknhnjsiiwinw' && $oauth->token_secret eq "lkmmmooppnjnqwuuuu5i5n5555", "from POST BODY");

eval {$oauth->request('protected_resource')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'protected_resource_url'}, 'Construct Request URL');

$oauth->from_hash(status => 'yo');
$oauth->sign;

$params = {
	(map {"oauth_".$_ => $oauth->{$_}} qw/consumer_key signature_method token timestamp nonce/),
	(%{ $config->{extra_params} }),
};
$params = [sort map { b($_)->url_escape."=".b($params->{$_})->url_escape } keys %$params];
is_deeply(
	[$oauth->params(delete => ['signature'])],
	$params,
	'Request Parameters For Signature'
);
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');
is($oauth->signature_base_string, join('&', 'POST', map {b($oauth->$_)->url_escape} qw/normalized_request_url normalized_message_parameters/), "Signature Base String");

is($oauth->signature_key, b($oauth->{'consumer_secret'})->url_escape."&".(b($oauth->{'token_secret'})->url_escape || ''), "check key for signing HMAC_SHA1 method");
is($oauth->signature, b( pack('H*', b($oauth->signature_base_string)->hmac_sha1_sum($oauth->signature_key)->to_string) )->b64_encode('')->to_string, "Signature");

is(
	$oauth->to_post_body, 
	join( '&', $oauth->params(extra => 1)),
	, "to POST BODY"
);
is(
	$oauth->to_header('Net::OAuth::All (Perl)'), 
	join( ',', 'OAuth realm="Net::OAuth::All (Perl)"',  $oauth->params(quote => '"', no_extra => 1) ),
	, "to HEADER"
);















diag("------OAuth 2.0");
$config = {
	type              => 'web_server',
	client_id         => '999999999999999',
	client_secret     => 'kjfdngh834hf49cc1ba4bb92b0502b',
	api_key           => 'fhgkjnfgu34h2hrjv34f',
	redirect_uri      => 'http://example.com/oauth/facebook/',
	authorization_url => 'https://graph.facebook.com/oauth/authorize',
	access_token_url  => 'https://graph.facebook.com/oauth/access_token',
	protected_resource_url => 'https://graph.facebook.com/me',
};
$oauth = eval {Net::OAuth::All->new(%$config)};
ok(!$@, $@ || "Successfully creation Net::OAuth::All object");

diag "------------authorization REQUEST";
eval {$oauth->request('authorization', 'token' => 'cgfgtoken', 'token_secret' => 'fhknkallopore')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'authorization_url'}, 'Construct Request URL');

$params = [
	sort map {$_."=".b($oauth->{$_})->url_escape} qw/type client_id redirect_uri/,
];
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');

is(
	$oauth->to_url,
	$oauth->url.'?'.join('&', $oauth->params),
	, "to URL"
);



diag "------------access_token REQUEST";
$oauth = eval {Net::OAuth::All->new(
	%$config,
	'code' => 'fghgqqq',#param from provider in callback
)};
ok(!$@, $@ || "Successfully creation Net::OAuth::All object");

eval {$oauth->request('access_token')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'access_token_url'}, 'Construct Request URL');

$params = [
	sort map {b($_)->url_escape."=".b($oauth->{$_})->url_escape} qw/type client_id client_secret code redirect_uri/,
];
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');



diag "------------protected_resource REQUEST";
$oauth->via('POST');
$oauth->response->from_post_body("access_token=kjknhnjsiiwinw");
ok($oauth->token eq 'kjknhnjsiiwinw', "from POST BODY");

eval {$oauth->request('protected_resource')};
is($@, '', "required parameter check is success");
is($oauth->normalized_request_url, $config->{'protected_resource_url'}, 'Construct Request URL');

$params = [
	sort map {b($_)->url_escape."=".b($oauth->{$_})->url_escape} qw/access_token/,
];
is($oauth->normalized_message_parameters, join("&", @$params), 'Normalize Request Parameters');

is(
	$oauth->to_post_body, 
	join( '&', $oauth->params),
	, "to POST BODY"
);
is(
	$oauth->to_header('Net::OAuth::All (Perl)'), 
	"OAuth ".$oauth->token,
	, "to HEADER 2.0"
);






