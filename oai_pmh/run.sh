#!/bin/bash -e

ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $ROOT

KOR_ROOT="/home/kor/rack/current"

# RUBY_VERSION=2.6.6

ruby client.rb
ruby combine.rb

mkdir $KOR_ROOT/public/oai-pmh-combined
cp \
  $ROOT/kor_xml/combined.free.xml \
  $ROOT/kor_xml/combined.nonfree.xml \
  $KOR_ROOT/public/oai-pmh-combined/
