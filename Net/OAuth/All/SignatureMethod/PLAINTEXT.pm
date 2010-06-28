package Net::OAuth::All::SignatureMethod::PLAINTEXT;
use warnings;
use strict;

sub sign {
	my ($self, $request) = @_;
	return $request->signature_key;
}

1;