#!/usr/bin/perl

use strict;
use warnings;
use WechatHomepageSpider;


my $biz = 'MzI1OTAwNDc1OA==';
my $hid = 1;
my $agent_name = 'DefaultSpider/0.1';

WechatHomepageSpider::scan_homepage($biz, $hid, $agent_name);
WechatHomepageSpider::download_homepage($biz, $hid, $agent_name);
