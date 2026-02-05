FROM nginx:alpine

# Borramos config default
RUN rm /etc/nginx/conf.d/default.conf

# Copiamos nuestra config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiamos el build de Flutter
COPY build/web /usr/share/nginx/html

EXPOSE 80
