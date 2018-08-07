// cloud functions for Firebase SDK to setup triggers
const functions = require("firebase-functions");
// Firebase admin SDK to access the Firebase Realtime Database
const firebase = require("firebase-admin");

const braintree = require("braintree");

// var gateway = braintree.connect({
//   environment: braintree.Environment.Sandbox,
//   merchantId: "7jpfvjy5xzbw7f9y",
//   publicKey: "cf8wggg6vtnntjzy",
//   privateKey: "d70f940369ffc731c38acd5e6edbc90e"
// });

module.exports.gateway = braintree.connect({
  environment: braintree.Environment.Sandbox,
  merchantId: "7jpfvjy5xzbw7f9y",
  publicKey: "cf8wggg6vtnntjzy",
  privateKey: "d70f940369ffc731c38acd5e6edbc90e"
});
module.exports.functions = functions;
module.exports.firebase = firebase;
