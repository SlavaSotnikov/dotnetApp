# # build stage
# FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
# WORKDIR /app

# COPY *.sln .
# COPY Products/*.csproj ./Products/
# RUN dotnet restore

# COPY Products/. ./Products/
# WORKDIR /app/Products
# RUN dotnet publish -c Release -o out

# # runtime stage
# FROM mcr.microsoft.com/dotnet/aspnet:6.0
# WORKDIR /app
# COPY --from=build /app/Products/out ./
# ENTRYPOINT ["dotnet", "Products.dll"]

####################  Build stage  ####################
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

####################  Runtime stage ###################
FROM nginx:1.25-alpine
# — видалимо стандартний default.conf
RUN rm /etc/nginx/conf.d/default.conf
# — копіюємо наш власний конфіг
COPY nginx.conf /etc/nginx/conf.d/default.conf
# — статичні файли React
COPY --from=build /app/build /usr/share/nginx/html

