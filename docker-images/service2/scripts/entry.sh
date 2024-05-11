#!/bin/bash

cd /code/service2
node index.js
nginx -g "daemon off;"

sleep infinity