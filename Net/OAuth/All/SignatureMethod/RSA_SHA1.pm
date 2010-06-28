package Net::OAuth::All::SignatureMethod::RSA_SHA1;
use warnings;
use strict;
use MIME::Base64;

sub sign {
	my ($self, $request, $key) = @_;
	$key ||= $request->signature_key;
	
	die '$request->signature_key must be an RSA key object (e.g. Crypt::OpenSSL::RSA) that can sign($text)'
		unless UNIVERSAL::can($key, 'sign');
	return encode_base64($key->sign($request->signature_base_string), "");
}

1;