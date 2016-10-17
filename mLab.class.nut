class mLab {
    // Copyright (c) 2015-6 Electric Imp
    // This file is licensed under the MIT License
    // http://opensource.org/licenses/MIT
    
    static version = [1,0,0];

    static API_BASE = "https://api.mlab.com/api/1/";
    static NO_DATABASE_ERROR = "No database selected";

    _apiKey = null;
    _db = null;

    constructor(apiKey, db = null) {
        _apiKey = apiKey;
        _db = db;
    }

    // Sets the current database.
    function use(db) {
        _db = db;
    }

    // Lists all available databases.
    function getDatabases(cb = null) {
        local reqUrl = API_BASE + "databases?apiKey=" + _apiKey;
        return _processRequest(http.get(reqUrl), cb);
    }

    // Lists all available collections in the current database.
    function getCollections(cb = null) {
        if (_noDbCheck(cb)) return;
        local reqUrl = API_BASE + "databases/" + _db + "/collections" + "?apiKey=" + _apiKey;
        return _processRequest(http.get(reqUrl), cb);
    }

    // Returns documents from the specified collection.
    // Any object can be passed into q, which will filter the
    // results to matching documents
    function find(collection, q, cb = null) {
        if (_noDbCheck(cb)) return;
        local reqUrl = API_BASE + "databases/" + _db + "/collections/" + collection + "?apiKey=" + _apiKey;
        if (q != null) reqUrl += "&" + _formatQuery(q);
        return _processRequest(http.get(reqUrl), cb);
    }

    // Inserts a new document into the specified collection
    function insert(collection, record, cb = null) {
        if (_noDbCheck(cb)) return;
        local reqUrl = API_BASE + "databases/" + _db + "/collections/" + collection + "?apiKey=" + _apiKey;
        local headers = { "Content-Type": "application/json" };
        return _processRequest(http.post(reqUrl, headers, http.jsonencode(record)), cb);
    }

    // Updates all documents in the specified collection
    // that match the query parameter
    function update(collection, multi, q, updateModifier, cb = null) {
        if (_noDbCheck(cb)) return;
        local reqUrl = API_BASE + "databases/" + _db + "/collections/" + collection + "?apiKey=" + _apiKey;
        if (q != null) reqUrl += "&" + _formatQuery(q);
        reqUrl += "&m=" + multi;
        local headers = { "Content-Type": "application/json" };
        return _processRequest(http.put(reqUrl, headers, http.jsonencode(updateModifier)), cb);
    }

    // Removes a document with the specified id from a collection
    function remove(collection, id, cb = null) {
        if (_noDbCheck(cb)) return;
        local reqUrl = API_BASE + "databases/" + _db + "/collections/" + collection + "/" + id + "?apiKey=" + _apiKey;
        local headers = { "Content-Type": "application/json" };
        return _processRequest(http.httpdelete(reqUrl, headers), cb);
    }

    //-------------------- PRIVATE METHODS --------------------//
    
    // Checks if a DB is set, and invokes the cb if not
    function _noDbCheck(cb) {
        if (_db == null) {
            local err = NO_DATABASE_ERROR;
            imp.wakeup(0, function() {
                cb(err, null, null);
            });
            return true;
        }

        return false;
    }

    // formats the querystring
    function _formatQuery(queryObj) {
        return http.urlencode({ q = http.jsonencode(queryObj) });
    }

    // Creates a response handler for _processRequest
    function _respHandlerFactory(cb) {
        return function(resp) {
            local err = null;
            local result = null;
            if (resp.statuscode != 200) {
                err = resp.body;
            } else {
                result = http.jsondecode(resp.body);
            }

            if (cb != null) {
                imp.wakeup(0, function() {
                    cb(err, resp, result);
                });
            }
        }.bindenv(this);
    }

    // Sends request and processes result
    // if a callback is supplied, request is asyncronous
    // if no callback is suppled, request is syncronous
    function _processRequest(req, cb = null) {;
        local respHandler = _respHandlerFactory(cb);
        return req.sendasync(respHandler.bindenv(this));
    }
}
