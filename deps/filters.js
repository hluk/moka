var Filters = {};

Filters.startWorker = function(w) {
    var data = w.data = w.filter.apply(w.data);
    self.postMessage(data);
    if (data === false) return;
    w.timer = setTimeout(function(){Filters.startWorker(w)}, 0);
}

Filters.pauseWorker = function(w) {
    var t = w.timer;
    if (t) { 
        clearTimeout(t);
        w.timer = null;
    }
}

Filters.resumeWorker = function(w) {
    if (w.timer === null && w.filter) {
        Filters.startWorker(w);
    }
}

Filters.workerMessage = function(data, FilterClass) {
    switch(data) {
        case "pause":
            Filters.pauseWorker(self);
            break;
        case "resume":
            Filters.resumeWorker(self);
            break;
        default:
            self.data = data;
            self.filter = new FilterClass();
            Filters.startWorker(self);
            break;
    }
}

