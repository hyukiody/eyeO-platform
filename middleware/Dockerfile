FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy identity-service from build context (set in docker-compose)
COPY identity-service/pom.xml ./pom.xml
COPY identity-service/src ./src

# Build the application (skip tests for faster builds)
RUN mvn clean package -Dmaven.test.skip=true

# Find and copy the Spring Boot jar
RUN JAR_PATH=$(find /app/target -maxdepth 1 -name "identity-service-*.jar" ! -name "*.original" -print -quit) \
	&& cp "$JAR_PATH" /app/identity-service.jar

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the built JAR
COPY --from=build /app/identity-service.jar app.jar

EXPOSE 8091

ENTRYPOINT ["java", "-jar", "app.jar"]
