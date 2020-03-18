FROM sictiy/hexo

WORKDIR /hexo

# gitclone到本地 再复制到容器内
COPY ./hblog-src /hexo

# 从git仓库clone到容器
#RUN echo "clone src file to hexo.." \
#	&& git clone https://github.com/Sictiy/hblog-src.git \
#	&& mv -rf ./hblog-src ./ \
#	&& rm -rf ./hblog-src

RUN echo "start run..." \
	&& npm config set registry https://mirrors.huaweicloud.com/repository/npm/ \
	&& npm config set disturl https://mirrors.huaweicloud.com/nodejs \
	&& npm cache clean -f \
	#&& npm config set proxy http://172.17.0.1:1080 \
	#&& npm config set https-proxy http://172.17.0.1:1080 \
	&& npm install -g npm \
	&& npm install

ENTRYPOINT ["sh", "/hexo/entrypoint.sh"]
