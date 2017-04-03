# WechatHomepageSpider

## Synopsis
A web crawler for Wechat homepage, written in **perl**

## How to use
```
# sample.pl
#!/bin/env perl

use strict;
use warnings;
use WechatHomepageSpider;

my $biz = 'Mzi42kJfmSAA==';
my $hid = 1;
my $agent_name = 'SampleSpider/0.1';

WechatHomepageSpider::scan_homepage($biz, $hid, $agent_name);
WechatHomepageSpider::download_homepage($biz, $hid, $agent_name);
```
and then
```
$ chmod 755 ./sample.pl
$ ./sample.pl
```
or
```
$ perl ./sample.pl
```

## TODO List
* Add special characters handle
* Multithreading
