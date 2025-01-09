# 使用官方 nginx 镜像
FROM nginx:1.25-alpine

# 复制 Nginx 配置文件到容器中
COPY backend.nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口 80
EXPOSE 80