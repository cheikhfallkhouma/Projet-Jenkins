FROM amazoncorretto:17-alpine

WORKDIR /app

COPY target/paymybuddy.jar paymybuddy.jar

ENV SPRING_DATASOURCE_USERNAME=""
ENV SPRING_DATASOURCE_PASSWORD=""
ENV SPRING_DATASOURCE_URL=""

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "paymybuddy.jar"]
