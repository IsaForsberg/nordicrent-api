'use strict';



require('dotenv').config();

const { MongoClient } = require('mongodb');

// One client for the whole server, created once and reused by every request.
// Connecting takes time (network) and every connection uses resources on the
// MongoDB server, so we do not create a new client per HTTP request.
// Same idea as the MySQL pool in db.js.
const client = new MongoClient(
  process.env.MONGO_URI || 'mongodb://127.0.0.1:27017'
);

// Has no value (undefined) until connectMongo() has run.
let reports;


// Opens the connection, then picks the database and the collection.
// Called once in start() in server.js, before the server starts listening.
async function connectMongo() {
  await client.connect();
const db = client.db(
    process.env.MONGO_DB || 'nordicrent_docs'
  );
 reports = db.collection('condition_reports');
}


// A function instead of exporting the variable directly: when server.js loads
// this file, reports is still undefined. The function reads the current value
// when it is called, after connectMongo() has run, and gives a clear error if
// MongoDB is not connected yet.
function reportsCollection() {
  if (!reports) {
    throw new Error('MongoDB is not connected');
  }

  return reports;
}


// Closes the connection, for example when the server fails to start.
async function closeMongo() {
  await client.close();
}


module.exports = {
  connectMongo,
  reportsCollection,
  closeMongo
};
