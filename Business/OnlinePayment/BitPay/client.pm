package Business::OnlinePayment::BitPay::Client;

use Carp;
use warnings;
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


sub new {
    my $class = shift;
    my %opts = @_;
    my $pem = $opts{"pem"}
        or croak "no pem passed to constructor";
    my $apiUri = "https://bitpay.com";
    my $id = Business::OnlinePayment::BitPay::KeyUtils::bpGenerateSinFromPem($pem);
    $apiUri = $opts{"apiUri"} if exists $opts{"apiUri"};
    return bless({pem => $pem, apiUri => $apiUri, id => $id}, $class);
}

sub get{
    my $self = shift;
    my %opts = @_;
    my $path = $opts{"path"};
    my $uri = $self->{apiUri} or croak "no api_uri exists for object";
    $uri = $uri . "/" . $path;
    my $request = HTTP::Request->new(GET => $uri);
    my $signature = Business::OnlinePayment::BitPay::KeyUtils::bpSignMessageWithPem($self->{pem}, $uri); 
    my $pubkey = Business::OnlinePayment::BitPay::KeyUtils::bpGetPublicKeyFromPem($self->{pem});
    $request->header('content-type' => 'application/json', 'X-Signature' => $signature, 'X-Identity' => $pubkey);
    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts( verify_hostname=> 0, SSL_ca_file => Mozilla::CA::SSL_ca_file(), SSL_Version => 'TLSv2', SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);
    my $response = $ua->request($request);
    return $response;
}

sub post{
    my $self = shift;
    my %opts = @_;
    my $path = $opts{"path"};
    my %content = %{%opts->{"params"}};
    my $uri = $self->{apiUri} or croak "no api_uri exists for object";
    $uri = $uri . "/" . $path;
    my $request = HTTP::Request->new(POST => $uri);
    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts( verify_hostname=> 0, SSL_ca_file => Mozilla::CA::SSL_ca_file(), SSL_Version => 'TLSv2', SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);
    my $jsonc = encode_json \%content;
    $request->content($jsonc);
    $request->header('content-type' => 'application/json');
    if ($content{"token"}){
        my $signature = Business::OnlinePayment::BitPay::KeyUtils::bpSignMessageWithPem($self->{pem}, $uri . $jsonc);
        my $pubkey = Business::OnlinePayment::BitPay::KeyUtils::bpGetPublicKeyFromPem($self->{pem});
        $request->header('X-Signature' => $signature, 'X-Identity' => $pubkey);
    }
    my $response = $ua->request($request);
    return $response if $response->is_success;
    my $code = $response->code;
    my $error = decode_json($response->content)->{'error'};
    croak "$code: $error"; 
}

sub process_response{
    my $response = @_[1];
    my @data = decode_json($response->content)->{'data'};
    return @data;
}

sub pair_client{
    my $self = shift;
    my %opts = @_;
    if($opts{"pairingCode"}){
        $code = $opts{"pairingCode"};
        pair_pos_client($self, $code);
    } else {
        pair_with_facade($self, %opts);
    }
}

sub pair_pos_client{
    my $self = shift;
    $code = $_[0];
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
    $content->{'facade'} = %opts{'facade'};
    my $id = $self->{id};
    $content->{'id'} = $id;
    $response = post($self, path => "tokens", params => $content);
    my @data = parse_json($response->content)->{'data'};
    return @data;
}
1;
