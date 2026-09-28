# =========================
# Stage 1: Build
# =========================
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .

COPY src ./src

RUN mvn clean package -DskipTests


# =========================
# Stage 2: Runtime
# =========================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root user
RUN useradd --system --uid 1001 appuser

# Copy only the packaged JAR
COPY --from=builder /app/target/habit-tracker.jar app.jar

# Run application as non-root user
USER 1001

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]