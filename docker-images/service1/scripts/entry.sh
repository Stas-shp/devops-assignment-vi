#!/bin/bash

cd /code/service1
node index.js
nginx -g "daemon off;"

sleep infinity