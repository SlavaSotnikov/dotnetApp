# build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY *.sln .
COPY Products/*.csproj ./Products/
RUN dotnet restore

COPY Products/. ./Products/
WORKDIR /app/Products
RUN dotnet publish -c Release -o out

# runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/Products/out ./
ENTRYPOINT ["dotnet", "Products.dll"]
