package Net::OAuth::All::SignatureMethod::HMAC_SHA1;
use warnings;
use strict;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64;

sub sign {
	my ($self, $request) = @_;
	return encode_base64(hmac_sha1($request->signature_base_string, $request->signature_key), '');
}

1;