#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use Business::OnlinePayment::BitPay::Client;
use WWW::Mechanize::PhantomJS;
use Data::Dumper;
require Business::OnlinePayment::BitPay::KeyUtils;

my $pairingCode;
my $client;
my $token;

Given 'the user pairs with BitPay with a valid pairing code', sub{
  sleep 2;
  open FILE, "stash/bitpay.pem" or die $!;
  my @lines = <FILE>;
  my $pem = join("", @lines);
  my $uri = "https://paul.bp:8088";
  my %options = ("pem" => $pem, "apiUri" => $uri);
  $client = Business::OnlinePayment::BitPay::Client->new(%options);
  my $response = $client->get(path => "tokens");
  my @data = $client->process_response($response);
  for my $mapp (values @data[0]){
    for my $key (keys %$mapp) {
      $token =  %$mapp{$key} if $key eq "merchant";
    }
  }
  my $params = {token => $token, facade => "pos", id => $client->{id}};
  $response = $client->post(path => "tokens", params => $params);
  @data = $client->process_response($response);
  $pairingCode = shift(shift(@data))->{'pairingCode'};
  die unless $pairingCode;
};

Then 'the user is paired with BitPay', sub {
  my $params = {pairingCode => $pairingCode, id => $client->{id}};
  my @data = $client->pair_pos_client($pairingCode);
  my $facade = shift(shift(@data))->{'facade'};
  die unless($facade eq "pos");
};

Given 'the user requests a client-side pairing', sub{
  sleep 2;
  open FILE, "stash/bitpay.pem" or die $!;
  my @lines = <FILE>;
  my $pem = join("", @lines);
  my $uri = "https://paul.bp:8088";
  my %options = ("pem" => $pem, "apiUri" => $uri);
  $client = Business::OnlinePayment::BitPay::Client->new(%options);
  my @data = $client->pair_client(facade => 'pos');
  $pairingCode = shift(shift(@data))->{'pairingCode'};
};

Then 'they will receive a claim code', sub{
  die unless($pairingCode =~ /\w{7}/);
}
