---
title: 记录一波配置https
date: 2019-03-17 21:00:00
categories: "配置"
---
# 申请ssl证书
- 申请腾讯的免费ssl证书
  - 点击[腾讯云免费ssl证书](https://www.qcloud.com/login)
  - 申请成功后查看证书相关参数
- 手动验证dns服务器
  - 申请一个域名
  - 根据申请ssl证书处的提示添加一条记录配置相应参数
- 等验证通过下载ssl文件
  - 一段时间以后收到邮件提示验证通过
  - 此时回到申请ssl的网站，可以下载ssl证书
# 编译安装
环境为 centos7，可以直接yum安装nginx
``sudo yum install nginx``
将上一步下载的ssl文件移动到nginx配置目录下方便配置
``mv 1_www.sictiyleon.xyz_bundle.crt /etc/nginx/ssl/``
# nginx配置
新建配置文件
``vim /etc/nginx/conf.d/www.sictiyleon.xyz``
主要内容为：
``server {
    listen 80;
    listen 443 ssl;
    server_name www.sictiyleon.xyz;
    charset utf-8;

    ssl on;

    #ssl配置
    ssl_certificate /etc/nginx/ssl/1_www.sictiyleon.xyz_bundle.crt;
    ssl_certificate_key  /etc/nginx/ssl/2_www.sictiyleon.xyz.key;
    ssl_session_timeout  5m;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers  HIGH:!ADH:!EXPORT56:RC4+RSA:+MEDIUM;

    location / {
        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
        client_max_body_size       1024m;
        client_body_buffer_size    128k;
        client_body_temp_path      /var/data/client_body_temp;
        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;
        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
        proxy_temp_path            /var/data/proxy_temp;

        proxy_pass http://127.0.0.1:4000;
    }
}``
# 启动nginx
启动nginx
``systemctl restart nginx``
启动失败，查看logs文件，发现不存在目录:/var/data/
``mkdir /var/data``
再次启动，看起来很正常。通过网址进入发现无法进去，提示5000。查看logs，有如下提示：
``*1012 socket() failed (24: Too many open files) while connecting to upstream, client: 127.0.0.1, server: www.sictiyleon.xyz, request: "GET / HTTP/1.0", upstream: "http://127.0.0.1:80/", host: "www.sictiyleon.xyz"
``
google以后得知是因为开启了selinux，于是临时关闭检验：
``setenforce 0``
再次重启nginx后可顺利通过https进入网页。
完。