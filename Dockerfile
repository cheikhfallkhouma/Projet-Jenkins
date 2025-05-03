FROM amazoncorretto:17-alpine

ARG JAR_FILE=target/paymybuddy.jar

WORKDIR /app

COPY ${JAR_FILE} paymybuddy.jar

ENV SPRING_DATASOURCE_USERNAME=root

ENV SPRING_DATASOURCE_PASSWORD=password

ENV SPRING_DATASOURCE_URL=jdbc:mysql://172.17.0.1:3306/db_paymybuddy

#CMD ["java", "-jar" , "paymybuddy.jar"]

# Copiez le fichier wait-for-it.sh dans le conteneur
COPY ./wait-for-it.sh /wait-for-it.sh

# Donnez les droits d'exécution au script
RUN chmod +x /wait-for-it.sh

# Modifiez la commande pour attendre la base de données avant de lancer l'application
CMD ["/wait-for-it.sh", "db:3306", "--", "java", "-jar", "paymybuddy.jar"]

