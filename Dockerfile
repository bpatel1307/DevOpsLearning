# Build image (multi-stage)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# copy csproj(s) first to leverage cache
COPY ["DevOpsLearning.csproj", "./"]
RUN dotnet restore "DevOpsLearning.csproj"

# copy everything and build/publish
COPY . .
RUN dotnet build "DevOpsLearning.csproj" -c ${BUILD_CONFIGURATION} -o /app/build
RUN dotnet publish "DevOpsLearning.csproj" -c ${BUILD_CONFIGURATION} -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
# create non-root user
ARG APP_USER=app
ARG APP_UID=1000
RUN adduser --disabled-password --gecos "" --uid ${APP_UID} ${APP_USER}

WORKDIR /app

# copy published app
COPY --from=build /app/publish .

# set environment so Kestrel listens on port 8000
ENV ASPNETCORE_URLS=http://+:8000
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8000

# adjust ownership of files for non-root user
RUN chown -R ${APP_USER}:${APP_USER} /app

USER ${APP_USER}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --spider http://127.0.0.1:8000/ || exit 1

ENTRYPOINT ["dotnet", "DevOpsLearning.dll"]
