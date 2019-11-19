FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-stretch AS build
WORKDIR /src
COPY ["Bot.Template.Community.Api/Bot.Template.Community.Api.csproj", "Bot.Template.Community.Api/"]
RUN dotnet restore "Bot.Template.Community.Api/Bot.Template.Community.Api.csproj"
COPY . .
WORKDIR "/src/Bot.Template.Community.Api"
RUN dotnet build "Bot.Template.Community.Api.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "Bot.Template.Community.Api.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Bot.Template.Community.Api.dll"]