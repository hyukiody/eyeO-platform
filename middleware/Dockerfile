FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy pom.xml and source
COPY pom.xml .
COPY src ./src

# Build the application (skip unit/integration test compilation to shorten builds)
RUN mvn clean package -Dmaven.test.skip=true

# Preserve the repackaged Spring Boot jar at a stable location for the final stage
RUN JAR_PATH=$(find /app/src/identity-service/target -maxdepth 1 -name "identity-service-*.jar" ! -name "*.original" -print -quit) \
	&& cp "$JAR_PATH" /app/identity-service.jar

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the built JAR
COPY --from=build /app/identity-service.jar app.jar

EXPOSE 8091

ENTRYPOINT ["java", "-jar", "app.jar"]
