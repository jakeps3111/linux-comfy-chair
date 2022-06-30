#!/usr/bin/env bash
# ruby.sh
# install ruby via the 'rbenv' system and some supporting plugins.

export PATH="$HOME/.rbenv/bin:$PATH"
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
# install dynamic bash extension
cd ~/.rbenv && src/configure && make -C src
# add the rbenv setup to our profile, only if it is not already there
if ! grep -qc 'rbenv init' ~/.bashrc ; then
  echo "## Adding rbenv to .bashrc ##"
  echo >> ~/.bashrc
  echo "# Set up Rbenv" >> ~/.bashrc
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
fi
# run the above command locally so we can get rbenv to work on this provisioning shell
eval "$(rbenv init - bash)"
# install a set of useful plugins for rbenv...
mkdir -p ~/.rbenv/plugins
git clone https://github.com/ianheggie/rbenv-binstubs.git ~/.rbenv/plugins/rbenv-binstubs
git clone https://github.com/sstephenson/rbenv-default-gems.git ~/.rbenv/plugins/rbenv-default-gems
git clone https://github.com/rbenv/rbenv-each.git ~/.rbenv/plugins/rbenv-each
git clone https://github.com/nabeo/rbenv-gem-migrate.git ~/.rbenv/plugins/rbenv-gem-migrate
git clone https://github.com/jf/rbenv-gemset.git ~/.rbenv/plugins/rbenv-gemset
git clone https://github.com/nicknovitski/rbenv-gem-update ~/.rbenv/plugins/rbenv-gem-update
git clone https://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/rbenv-update
git clone https://github.com/toy/rbenv-update-rubies.git ~/.rbenv/plugins/rbenv-update-rubies
git clone https://github.com/rkh/rbenv-whatis.git ~/.rbenv/plugins/rbenv-whatis
git clone https://github.com/yyuu/rbenv-ccache.git ~/.rbenv/plugins/rbenv-ccache

# set up a default-gems file for gems to install with each ruby...
echo $'bundler\nsassc\nrails\nrspec\nrspec-rails' > ~/.rbenv/default-gems
# set up .gemrc to avoid installing documentation for each gem...
echo "gem: --no-document" > ~/.gemrc

# check the version of OpenSSL installed.
if [[ $openssl_ver =~ "1.1.1" ]]; then
  echo "OpenSSL Version is good to use."
  openssl_dir="/usr/lib/ssl"
else
  echo "we need to install openssl 1.1.1"
  our_dir=$(pwd)
  # get a temporary directory to download openssl
  tmpdir=$(mktemp -d)
  cd $tmpdir
  # get the openssl source
  wget https://www.openssl.org/source/openssl-1.1.1o.tar.gz
  tar xf openssl-1.1.1o.tar.gz
  # build and install openssl
  cd openssl-1.1.1o
  ./config --prefix=/opt/openssl-1.1.1o --openssldir=/opt/openssl-1.1.1o shared zlib
  make
  make test
  sudo make install
  # link the system certs to openssl-1.1.1o
  sudo rm -rf /opt/openssl-1.1.1o/certs
  sudo ln -s /etc/ssl/certs /opt/openssl-1.1.1o
  # set the configure options for Ruby
  openssl_dir="/opt/openssl-1.1.1o"
  cd $our_dir
fi

configure_opts="--with-openssl-dir=${openssl_dir}"
echo "configure_opts: $configure_opts"



# install the required ruby version and set as default
RUBY_CONFIGURE_OPTS=$configure_opts rbenv install 2.7.6
rbenv install 3.1.2
rbenv global 2.7.6

# we need to erase 2 files temporarily (they will be regenerated) otherwise the installation will pause for overwrite confirmation
# These are the 'ri' and 'rdoc' scripts
rm ~/.rbenv/versions/2.7.6/bin/rdoc
rm ~/.rbenv/versions/2.7.6/bin/ri
# now update RubyGems and the default gems
gem update --system
gem update
