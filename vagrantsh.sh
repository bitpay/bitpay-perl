sudo apt-get update
sudo apt-get install -y openssl libssl-dev git cpanminus swig
git clone https://github.com/bitpay/bitpay-perl-keyutils.git
cd bitpay-perl-keyutils
./clean
sudo ./build
cd /vagrant
sudo cpanm Test::Exception Test::Fake::HTTPD Test::BDD::Cucumber JSON::Parse Mozilla::CA JSON IO::Socket::SSL LWP::Protocol::https
