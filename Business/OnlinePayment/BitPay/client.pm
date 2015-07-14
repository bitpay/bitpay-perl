package Business::OnlinePayment::BitPay::Client;

use Carp;
use strict;
require LWP::UserAgent;
require HTTP::Request;
require LWP::Protocol::https;
require Mozilla::CA;
require Business::OnlinePayment::Bitpay::KeyUtils;
use JSON;
use JSON::Parse 'parse_json';

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
    $ua->ssl_opts( SSL_ca_file => Mozilla::CA::SSL_ca_file() );
    my $response = $ua->request($request);
    my @data = parse_json($response->content)->{'data'};
    return @data;
}

1;
