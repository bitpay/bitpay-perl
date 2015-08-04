sub setClient{
    open FILE, "stash/bitpay.pem" or die $!;
    my @lines = <FILE>;
    $pem = join("", @lines);
    $uri = $BITPAYURL;
    my %options = ("pem" => $pem, "apiUri" => $uri);
    my $client = Business::OnlinePayment::BitPay::Client->new(%options);
    return $client;
};

1;

