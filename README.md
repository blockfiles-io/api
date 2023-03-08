# Blockfiles.io Main Server

This is the main server for blockfiles.io. It runs in an AWS Lambda function as a native Swift server. The underlying framework is [vapor](https://vapor.codes).

## Database

The database used is a MySQL database.

## Blockchain vs Database

The database is mostly used as a cache for the blockchain. Some metadata is stored in the database which is also returned through API but all ownership and IP related issues are strictly kept on-chain. 

The server is also checking the blockchain in real-time for requests (like downloads).
