const express = require("express");
var favicon = require("serve-favicon");
const path = require("path"); //#2 built-in Node module: works with files and directories
const app = express(); //#3 instantiate app object...

// uncomment after placing your favicon in /public
// app.use(favicon(path.join(__dirname, "public/images", "favicon.png")));
app.use(express.static(path.join(__dirname, "public")));

//** Add (body-parser) */
const bodyParser = require("body-parser");
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

//** Add (Braintree)/ (Promise) */
const braintree = require("braintree");
const Promise = require("promise");
const querystring = require("querystring");
var constants = require("./constants");
var db = require("./db");
var gateway = constants.gateway;
var functions = constants.functions;
var firebase = constants.firebase;

//#4 setup view engine (jade) and link to folder where templates are located.
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "jade");

//#5 the base url "/api/"
app.get("/:id", (req, res, next) => {
  var parts = req.params.id.split("_");
  console.log("parts:", parts);
  var isPaid = false;

  db.getUserData(parts[1])
    .then(function(data) {
      // check song paid
      var songs = data.PaidSongs;
      for (let i = 0; i < songs.length; i++) {
        const ele = songs[i];
        console.log(ele);
        if (parts[0] == ele) {
          isPaid = true;
        }
      }

      if (isPaid) {
        res.status(200);
        console.log("song is paid!");
      } else {
        //  get token and trigger render checkout/new
        generateToken(req, res)
          .then(function(results) {
            res.render("checkouts/new", {
              clientToken: results.clientToken,
              device: parts[1],
              item: parts[0],
              amount: "1.23"
            });
          })
          .catch(function(onRejected) {
            console.error("generateToken", onRejected);
          });
      }
    })
    .catch(function(onRejected) {
      console.error("unable to get DB", onRejected);
    });
});

app.post("/checkouts", (req, res) => {
  //=================
  var transactionErrors;
  var device = req.body.device;
  var item = req.body.item;
  console.log("redirect to /checkouts", item, device);

  var data = {
    amount: req.body.amount,
    paymentMethodNonce: req.body.payment_method_nonce,
    options: { submitForSettlement: true }
  };

  createTransaction(data)
    .then(function(results) {
      console.log("createTransaction results ok", results);

      findTransaction(results.transaction.id)
        .then(function(response) {
          console.log("findTransaction results ok", response);

          createResultObject(response)
            .then(function(obj) {
              console.log("createResultObject results ok", obj);

              // go to payment success page..
              res.render("checkouts/show", {
                transaction: response,
                result: obj
              });
              // then update database..
              db.getUserData(device)
                .then(function(userdata) {
                  var oldData = userdata.PaidSongs;

                  db.updateData(oldData, item, device)
                    .then(function(response) {
                      console.log("db updated", response);
                    })
                    .catch(function(onRejected) {
                      console.error("db updateData fail", onRejected);
                    });
                })
                .catch(function(onRejected) {
                  console.error("fail getUserdata", onRejected);
                });
            })
            .catch(function(onRejected) {
              console.log("createResultObject fail", obj);
            });
        })
        .catch(function(onRejected) {
          console.log("findTransaction fail", response);
        });
    })
    .catch(function(onRejected) {
      transactionErrors = result.errors.deepErrors();
      console.error("createTransaction", transactionErrors);
      res.redirect("checkouts/new");
    });
});

//#7 this line enables url "*/api/" to run
const api = functions.https.onRequest(app);

//#8 export 'app' object for other files to have access to it..
module.exports = { api };

/**
 *
 *
 *
 *
 * Functions for Braintree
 * Firebase account needs to have billing setup in order for
 * Braintree API to work
 *
 *
 *
 */

const TRANSACTION_SUCCESS_STATUSES = [
  braintree.Transaction.Status.Authorizing,
  braintree.Transaction.Status.Authorized,
  braintree.Transaction.Status.Settled,
  braintree.Transaction.Status.Settling,
  braintree.Transaction.Status.SettlementConfirmed,
  braintree.Transaction.Status.SettlementPending,
  braintree.Transaction.Status.SubmittedForSettlement
];

var generateToken = function(req, res) {
  return new Promise(function(resolve, reject) {
    gateway.clientToken.generate({}, (err, response) => {
      if (err) {
        reject(201);
      } else {
        resolve(response);
      }
    });
  });
};

var findTransaction = function(id) {
  return new Promise(function(resolve, reject) {
    gateway.transaction.find(id, (err, response) => {
      if (err) {
        reject(err);
      } else {
        resolve(response);
      }
    });
  });
};

var createTransaction = function(data) {
  return new Promise(function(resolve, reject) {
    gateway.transaction.sale(data, (err, result) => {
      if (result.success || result.transaction) {
        resolve(result);
      } else {
        reject(err);
      }
    });
  });
};

var createResultObject = function(transaction) {
  var result;
  var status = transaction.status;
  return new Promise(function(resolve, reject) {
    if (TRANSACTION_SUCCESS_STATUSES.indexOf(status) !== -1) {
      result = {
        header: "Sweet Success!",
        icon: "success",
        message:
          "Your test transaction has been successfully processed. See the Braintree API response and try again."
      };
      resolve(result);
    } else {
      result = {
        header: "Transaction Failed",
        icon: "fail",
        message:
          "Your test transaction has a status of " +
          status +
          ". Se ethe Braintree API response and try again."
      };
      reject(result);
    }
  });
};
