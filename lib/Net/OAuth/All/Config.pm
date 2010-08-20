package Net::OAuth::All::Config;
use warnings;
use strict;

use constant CONFIG => {
	'1_0' => {
		'sign_message' => 1,
		'access_token'       => {
			'required_params'  => [qw/consumer_key signature_method token/],
			'api_params'       => [qw/consumer_key signature_method signature token timestamp nonce/],
			'optional_params'  => [qw/version/],
		},
		'protected_resource' => {
			'required_params'  => [qw/consumer_key signature_method token token_secret/],
			'api_params'       => [qw/consumer_key signature_method signature token timestamp nonce/],
			'optional_params'  => [qw/version/],
		},
		'request_token'      => {
			'required_params'  => [qw/consumer_key signature_method/],
			'api_params'       => [qw/consumer_key signature_method signature timestamp nonce callback/],
			'optional_params'  => [qw/version/],
		},
		'authorization'      => {
			'required_params'  => [qw/token/],
			'api_params'       => [qw/token/],
			'optional_params'  => [qw/callback/],
		},
	},
	'1_0A' => {
		'sign_message' => 1,
		'access_token'       => {
			'required_params'  => [qw/consumer_key signature_method token verifier/],
			'api_params'       => [qw/consumer_key signature_method signature token timestamp nonce verifier/],
			'optional_params'  => [qw/version/],
		},
		'protected_resource' => {
			'required_params'  => [qw/consumer_key signature_method token token_secret/],
			'api_params'       => [qw/consumer_key signature_method signature token timestamp nonce/],
			'optional_params'  => [qw/version/],
		},
		'request_token'      => {
			'required_params'  => [qw/consumer_key signature_method/],
			'api_params'       => [qw/consumer_key signature_method signature timestamp nonce callback/],
			'optional_params'  => [qw/version/],
		},
		'authorization'      => {
			'required_params'  => [qw/token/],
			'api_params'       => [qw/token/],
			'optional_params'  => [qw/callback/],
		},
	},
	'2_0' => {
		'protected_resource' => {
			'required_params'  => [qw/access_token/],
			'api_params'       => [qw/access_token/],
			'optional_params'  => [qw//],
		},
		'web_server' => {
			'access_token'       => {
				'required_params'  => [qw/type client_id code/],
				'api_params'       => [qw/type client_id code/],
				'optional_params'  => [qw/format client_secret redirect_uri/],
			},
			'authorization'      => {
				'required_params'  => [qw/type client_id/],
				'api_params'       => [qw/type client_id/],
				'optional_params'  => [qw/state scope immediate redirect_uri/],
			},
		},
	},
};

1;