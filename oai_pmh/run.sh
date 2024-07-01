#!/bin/bash -e

ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $ROOT
RUBY="/usr/local/rbenv/shims/ruby"
KOR_ROOT="/var/storage/host/kor/current"

# RUBY_VERSION=2.6.6

$RUBY client.rb
$RUBY combine.rb

mkdir $KOR_ROOT/public/oai-pmh-combined
cp \
  $ROOT/kor_xml/combined.free.xml \
  $ROOT/kor_xml/combined.nonfree.xml \
  $KOR_ROOT/public/oai-pmh-combined/
