REM docker buildx create --name mbuilder
REM docker buildx use mbuilder
REM docker login -u username -p password

docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag davideciarmi/alpine-router .

pause