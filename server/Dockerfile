# Etapa 1: Compilación de la aplicación Dart en binario nativo
FROM dart:stable AS build

WORKDIR /app

# Copiar dependencias y resolver paquetes
COPY pubspec.* ./
RUN dart pub get

# Copiar el código fuente y compilar a binario ejecutable
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Etapa 2: Imagen final ultra ligera
FROM debian:bookworm-slim

WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/bin/server"]
