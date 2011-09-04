if (!self.window) {
    // worker
    importScripts('filters.js');
    self.onmessage = function(ev) {
        Filters.workerMessage(ev.data, Filters.Sharpen);
    }
}

Filters.Sharpen = function(strength, batch_size) {
    this.strength = strength ? Math.max(0,Math.min(1, strength)) : 0;
    this.batch_size = batch_size ? Math.max(1, batch_size) : 50;
}

Filters.Sharpen.prototype = {
    apply: function(options) {
        var dataDesc, data, dataCopy, e, h, mul, mulOther, w, w4, weight, y, miny;
        if (this._apply) return this._apply(options);

        dataDesc = options.dataDesc;
        data = dataDesc.data;
        dataCopy = options.dataDescCopy.data;

        w = dataDesc.width
        h = dataDesc.height
        mul = 15;
        mulOther = 1 + 3 * this.strength;
        weight = 1 / (mul - 4 * mulOther);
        mul *= weight;
        mulOther *= weight;
        w4 = w * 4;
        y = 1;

        miny = this.batch_size; // batch (lines)
        this._apply = function() {
            var b, g, nextY, offset, offsetNext, offsetPrev, offsetY, offsetYNext, offsetYPrev, prevY, r, x;

            if (y > h) {
                this._apply = null;
                return false;
            }

            offsetY = (y - 1) * w4;
            nextY = y === h ? y - 1 : y;
            prevY = y === 1 ? 0 : y - 2;
            offsetYPrev = prevY * w4;
            offsetYNext = nextY * w4;
            while (y < miny) {
                offsetY = (y - 1) * w4;
                nextY = y === h ? y - 1 : y;
                prevY = y === 1 ? 0 : y - 2;
                offsetYPrev = prevY * w4;
                offsetYNext = nextY * w4;
                x = w;
                offset = offsetY - 4 + w * 4;
                offsetPrev = offsetYPrev + (w - 2) * 4;
                offsetNext = offsetYNext + (w - 1) * 4;
                while (x) {
                    r = dataCopy[offset] * mul - mulOther * (dataCopy[offsetPrev] + dataCopy[offset - 4] + dataCopy[offset + 4] + dataCopy[offsetNext]);
                    g = dataCopy[offset + 1] * mul - mulOther * (dataCopy[offsetPrev + 1] + dataCopy[offset - 3] + dataCopy[offset + 5] + dataCopy[offsetNext + 1]);
                    b = dataCopy[offset + 2] * mul - mulOther * (dataCopy[offsetPrev + 2] + dataCopy[offset - 2] + dataCopy[offset + 6] + dataCopy[offsetNext + 2]);
                    data[offset] = Math.min(Math.max(r, 0), 255);
                    data[offset + 1] = Math.min(Math.max(g, 0), 255);
                    data[offset + 2] = Math.min(Math.max(b, 0), 255);
                    if (x < w) {
                        offsetNext -= 4;
                    }
                    --x;
                    offset -= 4;
                    if (x > 2) {
                        offsetPrev -= 4;
                    }
                }
                ++y;
                offsetY += w4;
                if (y !== h) {
                    ++nextY;
                    offsetYPrev += w4;
                }
                if (y > 2) {
                    ++prevY;
                    offsetYNext += w4;
                }
            }
            miny = Math.min(y + this.batch_size, h + 1);
            return dataDesc;
        };

        return this._apply(options);
    }
};

