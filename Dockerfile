# ==========================================
# ETAPA 1: LA COCINA (Le ponemos el apodo "builder")
# ==========================================
# Usamos una imagen oficial que ya trae Maven y Java 17.
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

# Creamos una carpeta de trabajo dentro del contenedor
WORKDIR /app

# TRUCO DE OPTIMIZACIÓN: Copiamos PRIMERO solo el pom.xml.
# ¿Por qué? Porque si tu código cambia pero tus dependencias no, 
# Docker usará la caché y no volverá a descargar todo internet.
COPY pom.xml .
RUN mvn dependency:go-offline

# Ahora sí, copiamos tu código fuente y lo compilamos saltando los tests para ir más rápido.
# Esto generará el archivo .jar dentro de una carpeta llamada /target
COPY src ./src
RUN mvn clean package -DskipTests

# ==========================================
# ETAPA 2: EL COMEDOR (La imagen final "runner")
# ==========================================
# Usamos una imagen que SOLO tiene el entorno de ejecución (JRE), mucho más liviana.
FROM eclipse-temurin:17-jre-alpine AS runner
WORKDIR /app

# REQUISITO DE LA RÚBRICA: Usuario no root.
# Por defecto, Docker ejecuta todo como superadministrador. Si te hackean la app, 
# hackean el contenedor entero. Aquí creamos un usuario sin privilegios llamado "springuser" 
# y un grupo "springgroup".
RUN addgroup --system --gid 1001 springgroup \
    && adduser --system --uid 1001 springuser

# EL PUENTE: Traemos el .jar desde la etapa "builder" a esta nueva etapa.
# Además, le damos la propiedad de este archivo a nuestro nuevo usuario seguro.
COPY --from=builder --chown=springuser:springgroup /app/target/*.jar app.jar

# Le decimos a Docker: "De ahora en adelante, ejecuta todo como este usuario seguro"
USER springuser

# Documentamos qué puerto usa tu app por defecto
EXPOSE 8080

# El comando final que ejecuta tu aplicación cuando el contenedor arranca
CMD ["java", "-jar", "app.jar"]