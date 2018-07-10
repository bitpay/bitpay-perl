package Business::OnlinePayment::BitPay::Client;
$VERSION = '2.3.2';

use Carp;
use warnings;
use strict;
use Mozilla::CA;
use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol::https;
use Business::OnlinePayment::BitPay::KeyUtils;
use JSON;
use JSON::Parse 'parse_json';
require IO::Socket::SSL;
use Net::SSLeay;
use Data::Dumper;

no warnings 'experimental';

sub new {
    my $class = shift;
    my %opts = @_;
    my $pem = $opts{"pem"}
        or croak "no pem passed to constructor";
    my $apiUri = "https://bitpay.com";
    my $id = Business::OnlinePayment::BitPay::KeyUtils::bpGenerateSinFromPem($pem);
    $apiUri = $opts{"apiUri"} if exists $opts{"apiUri"};
    return bless(
        {   pem    => $pem,
            apiUri => $apiUri,
            id     => $id,
            ua     => $opts{"ua"} // $class->_create_ua(),
        },
        $class
    );
}

sub _create_ua {
    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts(
        verify_hostname => 0,
        SSL_ca_file     => Mozilla::CA::SSL_ca_file(),
        SSL_Version     => 'TLSv12',
    );
    return $ua;
}

sub pair_client{
    my $self = shift;
    my %opts = @_;
    if($opts{"pairingCode"}){
        my $code = $opts{"pairingCode"};
        pair_pos_client($self, $code);
    } else {
        pair_with_facade($self, %opts);
    }
}

sub create_invoice{
    my $self = shift;
    my %opts = @_;
    my $price = delete $opts{'price'};
    my $currency = delete $opts{'currency'};
    croak "BitPay Error: Price must be formatted as a float" unless validate_price($price, $currency);
    croak "BitPay Error: Currency is invalid" unless validate_currency($currency);
    my $content = { %opts };
    $content->{'price'} = $price;
    $content->{'currency'} = $currency;
    my $id = $self->{id};
    $content->{'id'} = $id;
    my $token = retrieve_pos_or_merchant_token_from_server($self);
    $content->{'token'} = $token;
    my $response = post($self, path => "invoices", params => $content);
    my $data = parse_json($response->content)->{'data'};
    return %{$data};
}

sub get_invoice{
    my $self = shift;
    my %opts = @_;
    my $id = $opts{'id'};
    my $path = "invoices/" . $id;
    my $public = $opts{'public'};

    if (!$public) {
        my $token = retrieve_pos_or_merchant_token_from_server($self);
        $path .= "?token=$token" if $token;
    }

    my $response = get($self, path => $path, public => $public);
    my $data = parse_json($response->content)->{'data'};
    return %{$data};
}

sub get{
    my $self = shift;
    my %opts = @_;
    my $path = $opts{"path"};
    my $public = $opts{"public"};
    my $uri = $self->{apiUri} or croak "no api_uri exists for object";
    $uri = $uri . "/" . $path;
    my $request = HTTP::Request->new(GET => $uri);
    $request->header('content-type' => 'application/json');
    $request->header('X-BitPay-Plugin-Info' => 'PerlLib');
    $request->header('User-Agent' => 'perl-bitpay-client');
    unless($public){
        my $signature = Business::OnlinePayment::BitPay::KeyUtils::bpSignMessageWithPem($self->{pem}, $uri);
        my $pubkey = Business::OnlinePayment::BitPay::KeyUtils::bpGetPublicKeyFromPem($self->{pem});
        $request->header('X-Signature' => $signature, 'X-Identity' => $pubkey);
    }
    my $response = $self->{ua}->request($request);
    return $response if $response->is_success;
    my $code = $response->code;
    my $error = _decode_content($response->content)->{'error'};
    croak "$code: $error";
}

sub post{
    my $self = shift;
    my %opts = @_;
    my $path = $opts{"path"};
    my %content = %{$opts{"params"}};
    my $uri = $self->{apiUri} or croak "no api_uri exists for object";
    $uri = $uri . "/" . $path;
    utf8::encode($uri);
    my $request = HTTP::Request->new(POST => $uri);
    my $jsonc = encode_json \%content;
    $request->content($jsonc);
    $request->header('content-type' => 'application/json');
    $request->header('X-BitPay-Plugin-Info' => 'PerlLib');
    $request->header('User-Agent' => 'perl-bitpay-client');
    if ($content{"token"}){
        my $signature = Business::OnlinePayment::BitPay::KeyUtils::bpSignMessageWithPem($self->{pem}, $uri . $jsonc);
        my $pubkey = Business::OnlinePayment::BitPay::KeyUtils::bpGetPublicKeyFromPem($self->{pem});
        $request->header('X-Signature' => $signature, 'X-Identity' => $pubkey);
    }
    my $response = $self->{ua}->request($request);
    return $response if $response->is_success;
    my $code = $response->code;
    my $error = _decode_content($response->content)->{'error'};
    croak "$code: $error";
}

sub process_response{
    my $response = $_[1];
    my @data = decode_json($response->content)->{'data'};
    return @data;
}

sub pair_pos_client{
    my $self = shift;
    my $code = $_[0];
    croak "BitPay Error: Pairing Code is not legal" unless $code =~ /^\w{7}$/;
    my $id = $self->{'id'};
    my $content = {pairingCode => $code, id => $id};
    my $response = post($self, path => "tokens", params => $content);
    my @data = parse_json($response->content)->{'data'};
    return @data;
}

sub pair_with_facade{
    my $self = shift;
    my %opts = @_;
    my $content = {};
    $content->{'facade'} = $opts{'facade'};
    my $id = $self->{id};
    $content->{'id'} = $id;
    my $response = post($self, path => "tokens", params => $content);
    my @data = parse_json($response->content)->{'data'};
    return @data;
}

sub validate_price{
    my $price = $_[0];
    my $currency = $_[1];
    if($currency eq "BTC"){
        return 0 unless $price =~ /^\d+(\.\d{1,8})?$/;
    } else {
        return 0 unless $price =~ /^\d+(\.\d{1,2})?$/;
    };
    return 1;
}

sub validate_currency{
    my $currency = $_[0];
    return 0 unless $currency =~/^[A-Z]{3}$/;
    return 1;
}

sub retrieve_pos_or_merchant_token_from_server{
    my $token;
    my $self = shift;
    my $response = $self->get(path => "tokens");
    my @data = $self->process_response($response);
    for my $mapp (values $data[0]){
        for my $key (keys %$mapp) {
            if ($key eq "merchant" or $key eq "pos"){
                $token =  $mapp->{$key};
                last;
            }
        }
    }
    return $token if $token;
    croak "BitPay Error: No tokens on server";
}

sub _decode_content {
    my $data = shift;

    my $json = eval { decode_json($data) };
    if ($@) {
        die "JSON decode: ".$@."CONTENT:\n".$data;
    }
    return $json;
}

1;
