## MHA

The repo contains 2 services:
- coin-check
- ok

The `coin-check` service is a WebServer that checks for the value of Bitcoin in 
USD every 10 seconds and the average value over the last 10 minutes.

The `ok` service is a RESTful API that responds to GET requests on `/yes` with 
a 200 status code.

test
