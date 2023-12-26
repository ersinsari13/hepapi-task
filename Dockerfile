FROM amazoncorretto:17-alpine3.18
ENV SPRING_PROFILES_ACTIVE mysql
WORKDIR /app
COPY ./target/*.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]