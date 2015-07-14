use strict;
use Test::More tests => 4;
use Test::Exception;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;
use Test::Fake::HTTPD;
use JSON::Parse 'parse_json';
use Business::OnlinePayment::BitPay::KeyUtils;
use URI;

BEGIN{
    my $tokensResponse = '{"data":[{"policies":[{"policy":"id", "method":"inactive", "params":["TfFkHfxvFx7wvLtnqrudrZRqPEuwCpE8X9L"]}], "token":"DCvbrN5iXzo4X4s4bgBiDjS624o72MVQfacoghGWhCqz", "dateCreated":1436809787782, "pairingExpiration":1436896187782, "pairingCode":"Hgi0Tys"}]}';
    my $httpd = run_http_server {
        my $request = shift;
        my $uri = $request->uri;

        return do {
            if( $uri->path eq '/tokens' ){
                [
                    200,
                    [ 'Content-Type' => 'application/json' ],
                    [ $tokensResponse ]
                ]
            }
        }
    };

    my $uri = URI->new( $httpd->endpoint );

    my $string = "astring";
    my $pem = Business::OnlinePayment::BitPay::KeyUtils::bpGeneratePem();
    my %opt = ("pem" => $pem);
    $opt{"apiUri"} = $uri;
    use_ok('Business::OnlinePayment::BitPay::Client');
    ok(Business::OnlinePayment::BitPay::Client->new(%opt), "accept new with pem passed");
    throws_ok(sub { Business::OnlinePayment::BitPay::Client->new() }, qr/no pem passed to constructor/);
    my $client = Business::OnlinePayment::BitPay::Client->new(%opt);
    my @response = $client->pair_client;
    my $pairing = shift(shift(@response))->{'pairingCode'};
    is($pairing, "Hgi0Tys", "retrieves token data from endpoint"); #[0]->{"pairingCode"}); 
}

