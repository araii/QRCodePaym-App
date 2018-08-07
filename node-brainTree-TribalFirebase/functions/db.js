// -- require modules
var Promise = require("promise");

//

var constants = require("./constants");
var functions = constants.functions;
var admin = constants.firebase;
admin.initializeApp(functions.config().firebase);
var db = admin.database();

var getUserData = function(id) {
  return new Promise(function(resolve, reject) {
    var dbRef = db.ref("QRCodePaym").child(id);
    dbRef.once(
      "value",
      function(data) {
        if (data.val() != null) {
          console.log("db.getUserData", data.val());
          resolve(data.val());
        } else {
          createUser(id)
            .then(function(data) {
              resolve(data);
            })
            .catch(function(onRejected) {
              console.error("createUser fail", onRejected);
              reject(201);
            });
        }
      },
      function(error) {
        console.error("db.getUserData fail", error);
        reject(201);
      }
    );
  });
};

var createUser = function(id) {
  return new Promise(function(resolve, reject) {
    var writePath = db.ref("QRCodePaym").child(id);
    var data = {
      PaidSongs: [""]
    };
    writePath.set(data, function(error) {
      if (error) {
        reject(201);
      } else {
        resolve(data);
      }
    });
  });
};

var updateData = function(oldData, item, id) {
  console.log("db.js/ updateData");
  var writePath = db
    .ref("QRCodePaym")
    .child(id)
    .child("PaidSongs");

  var newData = [];
  for (let i = 0; i < oldData.length; i++) {
    newData.push(oldData[i]);
  }
  newData.push(item);
  console.log("new Data to update", newData);

  return new Promise(function(resolve, reject) {
    writePath.set(newData, function(error) {
      if (error) {
        reject(201);
      } else {
        resolve(200);
      }
    });
  });
};

module.exports.getUserData = getUserData;
module.exports.updateData = updateData;
