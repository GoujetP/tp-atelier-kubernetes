FROM node:20-alpine

#repertoire container
WORKDIR /app

COPY package.json ./

RUN npm install

COPY app.js ./

RUN mkdir -p /app/config

EXPOSE 3000

CMD ["npm", "start"]