# mLab

The mLab library is a wrapper class for the [mLab](https://mlab.com/) Data API. mLab is a hosted MongoDB as a service, and allows you a variety of options in terms of size, redundancy, etc.

For information about getting started with MongoLab and acquiring your MongoLab API key, see the [mLab Data API](http://docs.mlab.com/data-api/) documentation.

**Note** Although this code is version 1.0.0, it is functionally equivalent to version 2.0.0. of our mongoLab library, which this library replaces.

## Class Usage

### constructor(*apiKey[, db]*)

To create a new MongoDB object you will need your API key. You may also supply an optional database parameter to set the active database. If no database is selected, all methods that require a database will invoke the callback with an error until a database is selected with the *use()* method.

```squirrel
db <- mLab("<-- API_KEY -->", "<-- DATABASE_NAME -->");
```

### Callbacks

All methods in this class that interact with the database take an optional callback parameter. The callback takes three parameters: *err*, *response* and *data*:

- The *err* parameter will be `null` in a successful request, or contain a string describing the error.
- The *response* parameter is the [response table](https://electricimp.com/docs/api/httprequest/sendasync/) returned from the request.
- The *data* parameter will contain the decoded data from the request.

```squirrel
mlab.getDatabases(function(err, resp, databases) {
    if (err != null) {
        server.error(err);
        return;
    }

    foreach(database in databases) {
        server.log(database);
    }
});
```

### Active Database

All methods in the mLab class (with the exception of *use()* and *getDatabases()*) require an active database. The active database can be set using the second parameter of the constructor (suggested method), or by invoking with *use()* method with the desired database as the parameter.

## Class Methods

### use(*db*)

The *use()* method can be used to change the active database (ie. what database we’re running our queries against). This method should not be required in the majority of applications as the database should be set in the constructor.

```squirrel
db.use("someOtherDatabase");
```

### getDatabases(*[callback]*)

The *getDatabases()* method lists all of the databases attached to the account associated with the API key.

```squirrel
db.getDatabases(function(err, resp, databases) {
    if (err != null) {
        server.error(err);
        return;
    }

    foreach(database in databases) {
        server.log(database);
    }
});
```

### getCollections(*[callback]*)

The *getCollections()* method lists all collections (tables) in the active database.

```squirrel
db.getCollections(function(err, resp, collections) {
    if (err != null) {
        server.error(err);
        return;
    }

    foreach(collection in collections) {
      server.log(collection);
    }
});
```

### find(*collection, query[, callback]*)

The *find()* method invokes a query against the specified collection.

If an empty table is passed to the *query* parameter, find will return all records in the collection, otherwise, *find()* will execute the specified query, and return the results.

**Note** Information about building queries can be found in [mLab’s documentation](http://docs.mongodb.org/v2.6/reference/operator/query/).

```squirrel
// Return all users
db.find("users", {}, function(err, resp, users) {
    if (err != null) {
        server.error(err);
        return;
    }

    foreach(user in users) {
        server.log(http.jsonencode(user));
    }
});
```

```squirrel
// Return all records in the users collection that
// don't have a verified key (i.e. unverified users)
db.find("users", { "verified": { "$exists": false } }, function(err, resp, users) {
    if (err != null) {
        server.error(err);
        return;
    }

    foreach(user in users) {
        server.log(user._id["$oid"] + ": " + user.username);
    }
});
```

### insert(*collection, record[, callback]*)

The *insert()* method inserts a new record into the specified collection.

```squirrel
device.on("data", function(data) {
    local record = {
        ts = data.ts,
        temp = data.temp
    };

    db.insert("sensor_readings", record, function(err, resp, record) {
        if (err != null) {
            server.log(err);
            return;
        }

        server.log("Created record with id: " + record._id["$oid"]);
    });
});
```

### update(*collection, multi, q, updateModfier[, callback]*)

The *update()* method updates a collection’s records that match the specified query.

If the *multi* parameter is set to `false`, MongoLab will only update a single record, if the *multi* parameter is set to `true`, MongoLab will update all matching records. The *updateModifier* parameter can either be an object (in which case update will replace the record with the specified object) or contain an [Update Action](http://docs.mongodb.org/v2.6/reference/method/db.collection.update/#update-method-examples) (in which case update will take the specified action on all matching records).

**Note** If the *multi* flag is set to `true`, updateModifer *must* contain an update action.

```squirrel
// Update a single record:
local query = {
    "_id": { "$oid": "54d505afe4b05f6282260adf" }
};

local newRecord = {
    "username": "newUserName",
    "verified": false
};

db.update("users", false, query, newRecord, function(err, resp, data) {
    if (err != null) {
        server.log(err);
        return;
    }

    if (data.n == 0) {
        server.log("No matching records found!");
        return;
    }

    server.log("Success!");
});
```

```squirrel
// Find all records that are missing the verified flag, and add it
local query = {
    "verified": false
};

// Add the verified flag, and set it to false
local updateAction = {
    "$set": { "verified": true }
};

db.update("users", true, query, updateAction, function(err, resp, data) {
    if (err != null) {
        server.log(err);
        return;
    }

    if (data.n == 0) {
        server.log("No matching records found!");
        return;
    }

    server.log("Updated " + data.n + " records!");
});
```

### remove(*collection, id[, callback]*)

The *remove()* method removes the specified record from the specified collection.

```squirrel
// remove record with _id: { $oid: "54d505afe4b05f6282260adf" }
db.remove("users", "54d505afe4b05f6282260adf", function(err, resp, result) {
    if (err != null) {
        server.log(err);
        return;
    }

    server.log("Success!");
});
```

## License

This code is licensed under the [MIT License](./LICENSE).
