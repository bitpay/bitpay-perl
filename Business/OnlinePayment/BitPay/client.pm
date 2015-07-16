package Business::OnlinePayment::BitPay::Client;

use Carp;
use strict;
use Mozilla::CA;
use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol::https;
use Business::OnlinePayment::BitPay::KeyUtils;
use JSON;
use JSON::Parse 'parse_json';
use IO::Socket::SSL qw(debug3);
#require IO::Socket::SSL;
use Net::SSLeay;


sub new {
    my $class = shift;
    my %opts = @_;
    my $pem = $opts{"pem"}
        or croak "no pem passed to constructor";
    my $apiUri = "https://bitpay.com";
    my $id = Business::OnlinePayment::BitPay::KeyUtils::bpGenerateSinFromPem($pem);
    #my $id = "TfKncsE5bi1PMVkaSALZKjWo8BGaQVKKbty";
    $apiUri = $opts{"apiUri"} if exists $opts{"apiUri"};
    return bless({pem => $pem, apiUri => $apiUri, id => $id}, $class);
}

sub pair_client{
    my $self = shift;
    my $uri = $self->{apiUri} or croak "no api_uri exists for object";
    $uri = $uri . "/tokens";
    my $request = HTTP::Request->new(POST => $uri);
    $request->header('content-type' => 'application/json');
    my $id = $self->{id};
    my %content = ('id'=>$id);
    my $jsonc = encode_json \%content;
    $request->content($jsonc);
    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts( verify_hostname=> 0, SSL_ca_file => Mozilla::CA::SSL_ca_file(), SSL_Version => 'TLSv2', SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);
    my $response = $ua->request($request);
    print($response->as_string);
    my @data = parse_json($response->content)->{'data'};
    return @data;
}

1;
