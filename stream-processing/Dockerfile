FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy pom and source
COPY pom.xml ./
COPY src ./src

# Build the service
RUN mvn clean package -Dmaven.test.skip=true

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the built artifact
COPY --from=build /app/target/*.jar app.jar

# Add health check dependencies
RUN apk add --no-cache wget

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
