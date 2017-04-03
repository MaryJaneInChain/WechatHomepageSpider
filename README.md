# WechatHomepageSpider

## Synopsis
A web crawler for Wechat homepage, written in **perl**

## How to use
![Screenshot](https://github.com/MaryJaneInChain/WechatHomepageSpider/raw/master/docs/screenshot.png)
```
# example.pl
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
$ chmod 755 ./example.pl
$ ./example.pl
```
or
```
$ perl ./example.pl
```
the downloaded files will be like
```
Homepage Title ─┬─ Channel 1
                ├─ Channel 2
                ├─ Channel 3
                └─ Channel 4 ─┬─ Article 1.txt 
                              ├─ Article 1
                              ├─ Article 2.txt
                              └─ Article 2     ─┬─ cover.jpg
                                                ├─ img_0.jpg
                                                └─ img_1.jpg
```

## TODO List
* Add special characters handle
* Multithreading
