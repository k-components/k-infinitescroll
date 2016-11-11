// Generated by CoffeeScript 1.10.0
(function() {
  var InfiniteScroll, STEP_DEFAULT,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  STEP_DEFAULT = '10';

  module.exports = InfiniteScroll = (function() {
    function InfiniteScroll() {
      this.inViewport = bind(this.inViewport, this);
      this.fetchQuery = bind(this.fetchQuery, this);
      this.inserted = bind(this.inserted, this);
      this.infiniteScroll = bind(this.infiniteScroll, this);
    }

    InfiniteScroll.prototype.name = 'k-infinitescroll';

    InfiniteScroll.prototype.updating = false;

    InfiniteScroll.prototype.element = false;

    InfiniteScroll.prototype.datapath = null;

    InfiniteScroll.prototype.query = null;

    InfiniteScroll.prototype.step = null;

    InfiniteScroll.prototype.destroy = function() {
      return window.removeEventListener('scroll', this.infiniteScroll);
    };

    InfiniteScroll.prototype.create = function() {
      var fromMap, queryHash;
      this.datapath = this.model.get('datapath');
      this.subscribedIdList = this.model.get('subscribedidlist');
      this.element = document.getElementById(this.model.get('element'));
      this.step = parseInt(this.model.get('step') || STEP_DEFAULT, 10);
      this.model.root.on('insert', this.datapath, this.inserted);
      if (typeof window !== 'undefined') {
        window.addEventListener('scroll', this.infiniteScroll);
        fromMap = this.model.root._refLists.fromMap[this.datapath];
        if (fromMap) {
          queryHash = fromMap.idsSegments[1];
          return this.query = this.model.root._queries.get(queryHash);
        }
      }
    };

    InfiniteScroll.prototype.infiniteScroll = function() {
      var last;
      last = this.element && this.element.lastElementChild;
      if (last && this.inViewport(last)) {
        return this.fetchQuery();
      }
    };

    InfiniteScroll.prototype.inserted = function(index, arr) {
      var a, ids;
      if (index) {
        ids = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = arr.length; i < len; i++) {
            a = arr[i];
            if (a != null ? a.id : void 0) {
              results.push(a.id);
            }
          }
          return results;
        })();
        return this.model.root.insert(this.subscribedIdList, index, ids);
      }
    };

    InfiniteScroll.prototype.fetchQuery = function() {
      var newlength;
      if (this.query && !this.updating) {
        this.updating = true;
        newlength = this.model.root.get(this.subscribedIdList).length + this.step;
        this.query.expression['$limit'] = newlength;
        return this.query.fetch((function(_this) {
          return function(err) {
            if (err) {
              console.error(err);
            }
            return setTimeout((function() {
              return _this.updating = false;
            }), 500);
          };
        })(this));
      }
    };

    InfiniteScroll.prototype.inViewport = function(el) {
      var rect;
      if (el && el.getBoundingClientRect) {
        rect = el.getBoundingClientRect();
        return rect.top >= 0 && rect.left >= 0 && rect.bottom > 0 && rect.bottom - 20 <= (window.innerHeight || document.documentElement.clientHeight) && rect.right <= (window.innerWidth || document.documentElement.clientWidth);
      }
    };

    return InfiniteScroll;

  })();

}).call(this);
