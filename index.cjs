/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InfiniteScroll;
const STEP_DEFAULT = '10';

module.exports = (InfiniteScroll = (function () {
	InfiniteScroll = class InfiniteScroll {
		constructor() {
			this.infiniteScroll = this.infiniteScroll.bind(this);
			this.removed = this.removed.bind(this);
			this.inserted = this.inserted.bind(this);
			this.fetchQuery = this.fetchQuery.bind(this);
			this.inViewport = this.inViewport.bind(this);
			this.hashChanged = this.hashChanged.bind(this);
		}

		static initClass() {
			this.prototype.name = 'k-infinitescroll';
			this.prototype.updating = false;
			this.prototype.element = false;
			this.prototype.query = null;
			this.prototype.step = null;
		}

		destroy() {
			const listeners = this.model.get('listeners');

			if (this.datapath) {
				this.model.root.removeMutationListeners('insert', this.datapath, listeners);
			}

			if (this.model.get('alternativepath')) {
				this.model.root.removeMutationListeners('remove', this.model.get('alternativepath'), listeners);
			}

			if (this.scrollelement) { this.scrollelement.removeEventListener('scroll', this.infiniteScroll); }
			this.model.removeAllMutationListenersForTypeAndPath('change', 'hash');
			return this.scrollelement = (this.query = null);
		}

		create() {
			const listeners = [];
			this.debugName = this.model.get('debug');
			this.debugSequence = 0;
			this.inverted = this.model.get('inverted');
			this.datapath = this.model.get('datapath');
			this.subscribedIdList = this.model.get('subscribedidlist');
			this.element = document.getElementById(this.model.get('element'));
			const scrollelement = this.model.get('scrollelement');
			this.scrollelement = (scrollelement && document.getElementById(scrollelement)) || window;
			this.step = parseInt(this.model.get('step') || STEP_DEFAULT, 10);

			if (this.datapath) {
				listeners.push(this.model.root.on('insert', this.datapath, this.inserted));
			}

			if (this.model.get('alternativepath')) {
				listeners.push(this.model.root.on('remove', this.model.get('alternativepath'), this.removed));
			}

			setTimeout((() => {
				if (this.scrollelement) {
					return this.scrollelement.addEventListener('scroll', this.infiniteScroll(1));
				}
			}
			), 500);

			const hash = this.model.get('hash');
			this.model.on('change', 'hash', this.hashChanged);
			this.model.set('listeners', listeners);
			return this.query = this.model.root._queries.map[hash];
		}

		hashChanged(hash) {
			this.updating = false;
			this.query = hash ? this.model.root._queries.map[hash] : null;
		}

		debugLog(event, data) {
			if (!this.debugName || typeof console === 'undefined') { return; }
			console.info(`[${this.debugName} infinite scroll] ${event}`, data || {});
		}

		infiniteScroll(n) {
			if (n == null) { n = 1; }
			return () => {
				if (!document.body.contains(this.element)) {
					this.element = document.getElementById(this.model.get('element'));
				}

				const last = this.element && (this.inverted ? this.element.firstElementChild : this.element.lastElementChild);

				if (last && this.inViewport(last)) {
					this.debugLog('viewport-trigger', {
						updating: this.updating,
						limit: this.query && this.query.expression && this.query.expression.$limit
					});
					return this.fetchQuery(0)();
				} else if (n < 5) {
					return setTimeout((() => this.infiniteScroll(n + 1)), 50);
				}
			};
		}

		lazyload() {
			return window.myLazyLoad.update();
		}

		removed() {
			return this.infiniteScroll(1)();
		}

		inserted(idx, arr) {
			const insertedAt = typeof performance !== 'undefined' ? performance.now() : Date.now();
			if (window.myLazyLoad) {
				setTimeout(this.lazyload, 10);
				setTimeout(this.lazyload, 50);
				setTimeout(this.lazyload, 100);
				setTimeout(this.lazyload, 200);
			}

			if (this.subscribedIdList) {
				const existingIds = new Set(Array.from(this.model.root.get(this.subscribedIdList) || []));
				const ids = Array.from(arr)
					.filter((a) => (a != null ? a.id : undefined))
					.map((a) => a.id)
					.filter(id => {
						if (existingIds.has(id)) { return false; }
						existingIds.add(id);
						return true;
					});
				if (!ids.length) { return; }
				if (this.inverted) {
					this.model.root.insert(this.subscribedIdList, 0, ids.reverse());
				} else {
					this.model.root.insert(this.subscribedIdList, idx, ids);
				}
				this.debugLog('rows-inserted', {
					traceId: this.debugTraceId,
					added: ids.length,
					index: idx,
					requestElapsedMs: this.debugStartedAt == null ? null : Math.round((insertedAt - this.debugStartedAt) * 10) / 10
				});
				if (typeof requestAnimationFrame === 'function') {
					requestAnimationFrame(() => requestAnimationFrame(() => this.debugLog('rows-painted', {
						traceId: this.debugTraceId,
						totalElapsedMs: this.debugStartedAt == null ? null : Math.round(((typeof performance !== 'undefined' ? performance.now() : Date.now()) - this.debugStartedAt) * 10) / 10,
						renderedChildren: this.element ? this.element.childElementCount : null
					})));
				}
			}
		}

		fetchQuery(n) {
			return () => {
				if (this.query) {
					if (this.updating) {
						// Scroll and layout events commonly fire again while the current
						// page is rendering. Retrying here starts another page as soon as
						// the first refresh completes, even without a new user scroll.
						this.debugLog('refresh-already-running', { traceId: this.debugTraceId, ignored: true });
						return;
					} else {
						this.updating = true;
						this.debugTraceId = ++this.debugSequence;
						this.debugStartedAt = typeof performance !== 'undefined' ? performance.now() : Date.now();
						const previousLimit = this.query.expression['$limit'];

						// calculate the new length of the query
						// @subscribedIdList (and so the number of items we see on the page) may have grown since started
						// and we must set the new length of the query to reflect that. Thus, we can't just increase
						// the $limit by @step
						this.query.expression['$limit'] += this.step;
						this.debugLog('refresh-start', {
							traceId: this.debugTraceId,
							previousLimit,
							nextLimit: this.query.expression['$limit'],
							expression: this.query.expression
						});

						// If we have @subscribedIdList, we want to fetch, because the items are subscribed through the list. 
						// Otherwise we want to subscribe directly.
						return this.query.refresh(err => {
							if (err) { console.error(err); }
							this.debugLog('refresh-complete', {
								traceId: this.debugTraceId,
								elapsedMs: Math.round(((typeof performance !== 'undefined' ? performance.now() : Date.now()) - this.debugStartedAt) * 10) / 10,
								error: err ? `${err}` : null,
								resultCount: this.query && this.query.get ? (this.query.get() || []).length : null
							});
							return this.updating = false;
						});
					}
				}
			}
		}


		// bottom of the element doesn't have to show entirely, it's enough if the element is showing just partly (20 pixels from the bottom)
		inViewport(el) {
			if (el && el.getBoundingClientRect) {
				const rect = el.getBoundingClientRect();

				return (
					(rect.top >= 0) &&
					(rect.left >= 0) &&
					(rect.bottom > 0) &&
					((rect.bottom - 20) <= (window.innerHeight || document.documentElement.clientHeight))
				);
			}
		}
	};
	InfiniteScroll.initClass();
	return InfiniteScroll;
})());

