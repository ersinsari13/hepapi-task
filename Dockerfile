FROM amazoncorretto:17-alpine3.18
WORKDIR /app
COPY ./target/*.jar /app.jar
ENV SPRING_PROFILES_ACTIVE mysql
EXPOSE 8080
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]