if (!self.window) {
    // worker code
    importScripts('filters.js');
    self.onmessage = function(ev) {
        Filters.workerMessage(ev.data, Filters.Invert);
    }
}

Filters.Invert = function(batch_size) {
    this.batch_size = batch_size ? Math.max(1, batch_size) : 50;
}

Filters.Invert.prototype = {
    apply: function(options) {
        var dataDesc, data, w, h, y, miny;
        if (!options.dataDesc) return this._apply(options);

        dataDesc = options.dataDesc;
        data = dataDesc.data;
        w = dataDesc.width
        h = dataDesc.height

        y = 0;
        miny = this.batch_size; // batch (lines)
        this._apply = function() {
            var x;

            if (y >= h) {
                this._apply = null;
                return false;
            }

            offset = y*w*4;
            for(; y < miny; ++y) {
                for(x = 0; x < w; ++x) {
                    data[offset] = 255 - data[offset];
                    data[offset+1] = 255 - data[offset+1];
                    data[offset+2] = 255 - data[offset+2];
                    offset += 4;
                }
            }
            miny = Math.min(y + this.batch_size, h);
            return dataDesc;
        };

        return this._apply(options);
    }
};

