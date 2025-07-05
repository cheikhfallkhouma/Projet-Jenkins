# FROM amazoncorretto:17-alpine

# WORKDIR /app

# COPY target/paymybuddy.jar paymybuddy.jar

# ENV SPRING_DATASOURCE_USERNAME=""
# ENV SPRING_DATASOURCE_PASSWORD=""
# ENV SPRING_DATASOURCE_URL=""

# EXPOSE 8080

# ENTRYPOINT ["java", "-jar", "paymybuddy.jar"]

# Étape 1 : Construire l'application
FROM maven:3.8.5-openjdk-17 AS build

# Copier le projet dans le conteneur
COPY . /app

# Changer de répertoire
WORKDIR /app

# Construire l'application sans tests
RUN mvn clean install -DskipTests

# Étape 2 : Créer l'image à partir du jar
FROM openjdk:17-jdk-slim

# Créer un répertoire pour l'application
WORKDIR /app
RUN mkdir -p /app/logs

# Copier le fichier jar généré par Maven
COPY --from=build /app/target/paymybuddy.jar /app/paymybuddy.jar

# Copier le script de démarrage
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Exposer le port utilisé par Spring Boot
EXPOSE 8080

# Ne pas définir les variables d’environnement ici
# Elles seront injectées par Kubernetes à l’exécution

ENTRYPOINT ["/app/entrypoint.sh"]