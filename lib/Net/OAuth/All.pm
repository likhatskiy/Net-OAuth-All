package Net::OAuth::All;

use warnings;
use strict;
use Carp 'croak';
use Encode;
use URI;
use URI::Escape;
use Net::OAuth::All::Config;

our $VERSION = '0.7';

use constant OAUTH_PREFIX => 'oauth_';

our $OAUTH_PREFIX_RE = do {my $p = OAUTH_PREFIX; qr/^$p/};

sub new {
	my ($class, %args) = @_;
	$args{'current_request_type'}   = '';
	$args{'request_method'      } ||= 'GET';
	$args{'signature_method'    } ||= 'HMAC-SHA1';
	($args{'module_version'} = version_autodetect(\%args)) =~ s/\./\_/;
	$args{'__BASE_CONFIG'  }   = Net::OAuth::All::Config::CONFIG->{$args{'module_version'}} || {};
	croak 'Your Net::OAuth::All::Config is empty. Check params or insert "module_version" config!' unless %{ $args{'__BASE_CONFIG'} };
	
	if ($args{'signature_method'} && $args{'signature_method'} eq 'RSA-SHA1') {
		croak "Param 'signature_key_file' is null or file doesn`t exists" unless $args{'signature_key_file'} && -f $args{'signature_key_file'};
		
		smart_require('Crypt::OpenSSL::RSA', 1);
		smart_require('File::Slurp',         1);
		
		my $key = File::Slurp::read_file($args{'signature_key_file'});
		$args{'signature_key'} = Crypt::OpenSSL::RSA->new_private_key( $key );
	}
	
	bless \%args => $class;
}

sub version { shift->{'module_version'} }

sub version_autodetect {
	my $args = shift;
	
	return $args->{'module_version'} if $args->{'module_version'};
	
	unless ( grep {!$args->{$_}} qw/consumer_key consumer_secret/ ) {
		return $args->{'verifier'} ? '1.0A' : '1.0';
	}
	
	return '2.0' unless grep {!$args->{$_}} qw/client_id type/;
}

sub request {
	my ($self, $request_type, %args) = @_;
	
	croak "Request $request_type not suppoted!" unless %{ $self->base_requestconfig($request_type) };
	
	$self->{'current_request_type'}  = $request_type;
	$self->from_hash(%args) if %args;
	
	$self->check;
	$self->preload;
	return $self;
}

sub response {
	my ($self, $type, %args) = @_;
	delete $self->{$_} for qw/token token_secret/;
	return $self;
}

sub preload {
	my $self = shift;
	$self->{'timestamp'} = time;
	$self->{'nonce'    } = $self->gen_str;
	$self->sign if $self->sign_message;
}

sub check {
	my $self = shift;
	croak "Missing required parameter '$_'" for grep {not defined $self->{$_}} $self->required_params;
}

sub base_requestconfig {
	my ($self, $request_type) = @_;
	$request_type ||= $self->{'current_request_type'};
	
	return (
		($self->{'module_version'} eq '2_0' and not grep {$request_type =~ /$_/} qw/refresh protected/)
			?
				$self->{'__BASE_CONFIG'}->{$self->{'type'}}->{$request_type}
			:
				$self->{'__BASE_CONFIG'}->{$request_type}
	) || {};
}

sub params {
	my ($self, %opts) = @_;
	
	$opts{'quote' } = "" unless defined $opts{'quote'};
	$opts{'delete'} = {map {$_ => 1} @{ $opts{'delete'}  || []}};
	
	my %params = ();
	unless ($opts{'extra'}) {
		if ($self->{'module_version'} eq '2_0') {
			%params = map {$_ => $self->{$_}}
				$self->api_params, grep {$self->{$_}} $self->optional_params, @{$opts{add}};
		} else {
			%params = 
				map  {OAUTH_PREFIX.$_ => $self->{$_}}
				grep {!$opts{'delete'}->{$_}}
				$self->api_params, grep {$self->{$_}} $self->optional_params;
			
		}
	}
	my $extra = $self->extra;
	if ($extra && !$opts{'no_extra'}) {
		$params{$_} = $extra->{$_} for keys %$extra;
	}
	
	return \%params if $opts{'hash'};
	
	return sort map {join '=', escape($_), $opts{'quote'} . escape($params{$_}) . $opts{'quote'}} keys %params;
}

sub to_header {
	my ($self, $realm, $sep) = @_;
	$sep  ||= ",";
	$realm  = defined $realm ? "realm=\"$realm\"$sep" : "";
	
	return "OAuth $realm" .
		join($sep, $self->params(quote => '"', no_extra => 1)) if $self->version ne '2_0';
	
	return "OAuth $self->{'access_token'}";
}

sub to_url {
	my $self  = shift;
	my $extra = shift;
	
	my $url = $self->url;
	
	if (defined $url) {
		_ensure_uri_object($url);
		$url = $url->clone; # don't modify the URL that was passed in
		$url->query(undef); # remove any existing query params, as these may cause the signature to break
		my $p_str = join '&' => $self->params(extra => $extra);
		return $url . ($p_str ? '?'.$p_str : '');
	} else {
		croak "Can`t load $self->{'current_request_type'} request URL";
	}
}

sub from_hash {
	my ($self, %hash) = @_;
	
	if ($self->{'module_version'} eq '2_0') {
		$self->{$_} = $hash{$_} for keys %hash;
	} else {
		foreach my $k (keys %hash) {
			if ($k =~ s/$OAUTH_PREFIX_RE//) {
				$self->{$k} = $hash{OAUTH_PREFIX . $k};
			} else {
				$self->{$k} = $hash{$k};
			}
		}
	}
	
	return $self;
}

sub to_hash      { shift->params(hash => 1) }

sub to_post_body {
	my $self = shift;
	return '' if $self->via eq 'GET';
	
	my $extra;
	$extra = 1 if $self->version ne '2_0';
	
	join '&', $self->params(extra => $extra);
	#~ '';
}

sub from_post_body {
	my ($self, $post_body) = @_;
	croak "Provider sent error message '$post_body'" if $post_body =~ /\s/;
	return $self->from_hash(map {unescape($_)} grep {s/(^"|"$)//g;1;} map {split '=', $_, 2} split '&', $post_body);
}

#sign
sub sign {
	my $self = shift;
	my $class = $self->_signature_method_class;
	$self->signature($class->sign($self, @_));
	return $self;
}

sub _signature_method_class {
	my $self = shift;
	(my $signature_method = $self->signature_method) =~ s/\W+/_/g;
	my $sm_class = 'Net::OAuth::All::SignatureMethod::' . $signature_method;
	croak "Unable to load $signature_method signature plugin. Check signature_method" unless smart_require($sm_class);
	return $sm_class;
}

sub signature_key {
	my $self = shift;
	# For some sig methods (I.e. RSA), users will pass in their own key
	my $key = $self->{'signature_key'};
	unless (defined $key) {
		$key = escape($self->{'consumer_secret'}) . '&';
		$key .= escape($self->{'token_secret'}) if $self->{'token_secret'};
	}
	return $key;
}

sub sign_message {+shift->{'__BASE_CONFIG'}->{'sign_message'} || 0}
sub _ensure_uri_object { $_[0] = UNIVERSAL::isa($_[0], 'URI') ? $_[0] : URI->new($_[0]) }

sub normalized_request_url {
	my $self = shift;
	my $url = $self->url;
	_ensure_uri_object($url);
	$url = $url->clone;
	$url->query(undef);
	return $url;
}

sub normalized_message_parameters { join '&',  shift->params('delete' => ['signature']) }
sub signature_base_string {
	my $self = shift;
	return join '&', map {escape($self->$_)} qw/via normalized_request_url normalized_message_parameters/;
}

#----------------

our %ALREADY_REQUIRED = ();

sub smart_require {
	my $required_class = shift;
	my $croak_on_error = shift || 0;
	unless (exists $ALREADY_REQUIRED{$required_class}) {
		$ALREADY_REQUIRED{$required_class} = eval "require $required_class";
		croak $@ if $@ and $croak_on_error;
	}
	return $ALREADY_REQUIRED{$required_class};
}

#params list
sub required_params { @{ shift->base_requestconfig->{'required_params'} || {}} }
sub api_params      { @{ shift->base_requestconfig->{'api_params'     } || {}} }
sub optional_params { @{ shift->base_requestconfig->{'optional_params'} || {}} }

sub put_extra {
	my $self = shift;
	my %p    = @_;
	
	$self->{'extra_params'}->{$_} = $p{$_} for keys %p;
	return $self;
}
sub extra {shift->{'extra_params'} || {} }
sub clean_extra {
	my $self = shift;
	$self->{'extra_params'} = {};
	return $self;
}

#take params
sub token {
	for (+shift) {
		return $_->{ $_->{'module_version'} eq '2_0' ? 'access_token' : 'token' };
	}
}

sub token_secret  { shift->{'token_secret' }       }
sub expires       { shift->{'expires'      } || 0  }
sub scope         { shift->{'scope'        } || '' }
sub refresh_token { shift->{'refresh_token'} || '' }
sub url   {
	my $self = shift;
	$self->{$self->{'current_request_type'}."_url"};
}
sub signature {
	my ($self, $value) = @_;
	$self->{'signature'} = $value and return $self if defined $value;
	
	return $self->{'signature'};
}

sub signature_method {
	my ($self, $value) = @_;
	$self->{'signature_method'} = $value and return $self if defined $value;
	
	return $self->{'signature_method'} || '';
}

sub via {
	my ($self, $value) = @_;
	$self->{'request_method'} = $value and return $self if defined $value;
	
	return $self->{'request_method'};
}

sub request_type {
	shift->{'current_request_type'};
}

sub protected_resource_url {
	my ($self, $value) = @_;
	$self->{'protected_resource_url'} = $value and return $self if defined $value;
	
	return $self->{'protected_resource_url'};
}

#extra subs
sub escape {
	my $str = shift || "";
	$str = Encode::decode_utf8($str, 1) if $str =~ /[\x80-\xFF]/ && Encode::is_utf8($str);
	
	return URI::Escape::uri_escape_utf8($str,'^\w.~-');
}

sub unescape { uri_unescape(shift) }

our $tt = [0..9, 'a'..'z', 'A'..'Z'];

sub gen_str { join '', map {$tt->[rand @$tt]} 1..16 }

1;