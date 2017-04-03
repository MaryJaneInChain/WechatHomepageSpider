#!/bin/env perl

package WechatHomepageSpider;

use strict;
use warnings;
use utf8;
use Switch;
use Encode;
use Encode::Guess;
use LWP::UserAgent;
use LWP::Simple;
use JSON;
use HTML::TreeBuilder;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# **********************************************
# Function Name: scan_page($user_agent, $biz, $channel_id, $title, $channel_name, $begin, $count)
# **********************************************
sub scan_page{
	my $user_agent = shift;
	my $biz = shift;
	my $hid = shift;
	my $channel_id = shift;
	my $title = shift;
	my $channel_name = shift;
	my $begin = shift;
	my $size = shift;
	my $uri = 'http://mp.weixin.qq.com/mp/homepage';
	my $param = '__biz='.$biz.'&hid='.$hid.'&cid='.$channel_id.'&begin='.$begin.'&count='.$size.'&action=appmsg_list&f=json&r=0.5';
	my $count = 0;

	my $request = HTTP::Request->new(POST => $uri);
	$request->content_type('application/x-www-form-urlencoded');
	$request->content($param);

	my $response = $user_agent->request($request);

	if($response->is_success){
		my $result = decode_json($response->content);
		my @appmsg_list = @{%$result{'appmsg_list'}};
		my $list_length = @appmsg_list;
		return 0 unless $list_length > 0;

		foreach my $value (@appmsg_list){
			$count += 1;
			print "采集了栏目 ".($channel_name)." 中的 ".($$value{'title'})."\n";

			open(my $article_handle, '>', $title.'/'.$channel_name.'/'.$$value{'title'}.'.txt') or die('无法打开 '.$$value{'title'}.'.txt：'.$!);
			binmode($article_handle, ':encoding(utf8)');
			print $article_handle "title: $$value{'title'}\n";
			print $article_handle "cover: $$value{'cover'}\n";
			print $article_handle "link: $$value{'link'}\n";
			print $article_handle "digest: $$value{'digest'}\n";

			close($article_handle);
		}

		return 1;
	}else{
		die($response->status_line."\n");
	}
}

# **********************************************
# Function Name: scan_channel($user_agent, $biz, $channel_id, $title, $channel_name)
# **********************************************
sub scan_channel{
	my $user_agent = shift;
	my $biz = shift;
	my $hid = shift;
	my $channel_id = shift;
	my $title = shift;
	my $channel_name = shift;

	my $begin = 0;
	my $count = 5;

	while(scan_page($user_agent, $biz, $hid, $channel_id, $title, $channel_name, $begin, $count)){
		$begin += 5;
	}
}

# **********************************************
# Function Name: scan_homepage($biz, $hid, $agent_name)
# **********************************************
sub scan_homepage{
	my $biz = shift;
	my $hid = shift;
	my $agent_name = shift;
	my $uri = 'http://mp.weixin.qq.com/mp/homepage?__biz='.$biz.'&hid='.$hid;

	my $user_agent = LWP::UserAgent->new;
	$user_agent->agent($agent_name);

	my $request = HTTP::Request->new(GET => $uri);
	$request->content_type('application/x-www-form-urlencoded');

	my $response = $user_agent->request($request);

	my $tree = HTML::TreeBuilder->new();
	$tree->parse($response->decoded_content);
	$tree->eof();

	my @title = $tree->look_down(
		_tag 	=> 	'title'
	);
	my $title = $title[0]->as_text();
	$title =~ s/^\s+|\s+$//g;
	if($title eq '错误'){
		print("采集失败，请检查biz与hid是否正确\n");
		exit;
	}

	my @channel_list = $tree->look_down(
		_tag 	=> 	'div',
		class 	=> 	qr/item/,
		type 	=> 	'index'
	);
	my $channel_count = @channel_list;

	if(not(-d $title)){
		mkdir($title) or die('创建文件夹 '.$title.' 失败！');
	}

	foreach my $channel_id(0..($channel_count - 1)){
		my $channel_name = $channel_list[$channel_id]->as_text();
		mkdir($title.'/'.$channel_name);
		scan_channel($user_agent, $biz, $hid, $channel_id, $title, $channel_list[$channel_id]->as_text());
	}

	$tree->delete();
}

# **********************************************
# Function Name: handle_line($line, $folder_path, $article_handle)
# **********************************************
sub handle_line{
	my $line = shift;
	my $folder_path = shift;
	my $article_handle = shift;
	my $user_agent = shift;

	$line =~ /\:\ /o;
	my $key = $`;
	my $value = $';
	$value =~ s/\n//;

	# 根据key对value进行相应的动作
	switch($key){
		# 下载封面
		case 'cover'{
			my $cover = get($value);
			open(my $cover_handle, '>', "$folder_path/cover.jpg");
			binmode($cover_handle);
			print $cover_handle $cover;
			close($cover);
		}
		# 拉取文章其余部分
		case 'link'{
			while(<$article_handle>){};

			my $request = HTTP::Request->new(GET => $value);
			$request->content_type('application/x-www-form-urlencoded');
			my $response = $user_agent->request($request);

			my $tree = HTML::TreeBuilder->new();
			$tree->parse($response->decoded_content);
			$tree->eof();
			
			my @date = $tree->look_down(
				_tag 	=> 	'em',
				id  	=> 	'post-date'
			);
			my $date = $date[0]->as_text();
			print $article_handle "date: $date\n\n";

			my @article = $tree->look_down(
				_tag 	=> 	'div',
				id 		=> 	'js_content'
			);

			@article = $article[0]->look_down(
				_tag 		=> 	'p',
				_content 	=> 	qr/.*/
			);
			
			my $img_count = 0;
			foreach my $line (@article){
				if(my $child_img = ($line->look_down('_tag', 'img'))[0]){
					my $src = $child_img->attr('data-src');
					my $img_type = 'gif';
					if(defined $child_img->attr('data-type')){
						$img_type = $child_img->attr('data-type') ;
					}
				
					my $img = get($src);
					open(my $img_handle, '>', "$folder_path/img_$img_count.$img_type");
					binmode($img_handle);
					print $img_handle $img;
					close($img_handle);

					print $article_handle "[img_$img_count";
					$img_count++;

					if(my $child_span = ($line->look_down('_tag', 'span', '_content', qr/.+/))[0]){
						print $article_handle ' '.$child_span->as_text();
					}
					print $article_handle "]\n";
					next;
					
				}
				my $text = $line->as_text();
				if($text ne ''){
					print $article_handle "$text\n";
				}
			}

			$tree->delete();
		}
	}
}

# **********************************************
# Function Name: download_article($uri, $folder_path, $user_agent)
# **********************************************
sub download_article{
	my $article = shift;
	my $folder_path = shift;
	my $user_agent = shift;

	open(my $article_handle, '+<', $folder_path.'/'.$article) or die('无法打开 '.$article.'： '.$!);
	binmode($article_handle, ':encoding(utf8)');

	while(my $line = <$article_handle>){
		my $title = $article;
		$title =~ s/.txt//;
		my $resource_path = $folder_path.'/'.$title;
		mkdir($resource_path);
		handle_line($line, $resource_path, $article_handle, $user_agent);
	}
}

# **********************************************
# Function Name: download_homepage($biz, $hid, $agent_name)
# **********************************************
sub download_homepage{
	my $biz = shift;
	my $hid = shift;
	my $agent_name = shift;
	my $homepage_uri = 'http://mp.weixin.qq.com/mp/homepage?__biz='.$biz.'&hid='.$hid;

	my $user_agent = LWP::UserAgent->new;
	$user_agent->agent($agent_name);

	my $request = HTTP::Request->new(GET => $homepage_uri);
	$request->content_type('application/x-www-form-urlencoded');

	my $response = $user_agent->request($request);

	my $tree = HTML::TreeBuilder->new();
	$tree->parse($response->decoded_content);
	$tree->eof();

	my @title = $tree->look_down(
		_tag 	=> 	'title'
	);
	my $title = $title[0]->as_text();
	$title =~ s/^\s+|\s+$//g;

	my @channel_list = $tree->look_down(
		_tag 	=> 	'div',
		class 	=> 	qr/item/,
		type 	=> 	'index'
	);
	my $channel_count = @channel_list;

	if(not(-d $title)){
		mkdir($title) or die('创建文件夹 '.$title.' 失败！');
	}

	foreach my $channel_id(0..($channel_count - 1)){
		my $channel_name = $channel_list[$channel_id]->as_text();
		my $channel_path = $title.'/'.$channel_name;
		opendir(my $articles, $channel_path);
		my @articles = readdir($articles);
		foreach my $article(grep(/^.*\.txt$/,@articles)){
			$article = Encode::decode('Guess', $article);
			if($article eq '.' or $article eq '..'){
				next;
			}
			print '开始下载 '.$channel_path.'/'.$article."\n";
			download_article($article, $channel_path, $user_agent);
			print '已下载 '.$channel_path.'/'.$article."\n";
		}
		closedir($articles);
	}

	$tree->delete();
}
