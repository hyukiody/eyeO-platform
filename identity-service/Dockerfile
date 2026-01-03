# Multi-stage build for optimized Docker image
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy pom and source
COPY pom.xml ./
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Copy only the built artifact
COPY --from=build --chown=spring:spring /app/app.jar app.jar

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

USER spring:spring

EXPOSE 8081

# Use exec form for proper signal handling
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
