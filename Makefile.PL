use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Business::OnlinePayment::BitPay::Client',
    VERSION         => '2.1',
    PREREQ_PM       => {
        'Carp' => '0',
        'Mozilla::CA' => '0',
        'LWP::UserAgent' => '0',
        'HTTP::Request' => '0',
        'LWP::Protocol::https' => '0',
        'Business::OnlinePayment::BitPay::KeyUtils' => '0',
        'JSON' => '0',
        'JSON::Parse' => '0',
        'IO::Socket::SSL' => '0',
        'Net::SSLeay' => '0',
        'Test::Exception' => '0',
        'Test::Fake::HTTPD' => '0'
    }
);

