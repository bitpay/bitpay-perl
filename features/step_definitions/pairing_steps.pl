#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use Business::OnlinePayment::BitPay::Client;
require Business::OnlinePayment::BitPay::KeyUtils;

Given 'the user pairs with BitPay with a valid pairing code', sub {
  my $pem = Business::OnlinePayment::BitPay::KeyUtils::bpGeneratePem();
  #my $pem = "your mom";
  my $uri = "https://paul.bp:8088";
  my %options = ("pem" => $pem, "apiUri" => $uri);
  my $client = Business::OnlinePayment::BitPay::Client->new(%options);
  my @response = $client->pair_client;
  our $pairing_code = shift(shift(@response))->{'pairingCode'};
};
