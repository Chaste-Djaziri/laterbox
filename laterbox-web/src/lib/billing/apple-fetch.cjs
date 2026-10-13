// The Apple SDK uses node-fetch v2, including buffer() for OCSP responses.
// Use the Workers fetch transport without mutating its global fetch function.
async function appleFetch(input, init = {}) {
  const { timeout, ...options } = init;
  if (timeout > 0) {
    const timeoutSignal = AbortSignal.timeout(timeout);
    options.signal = options.signal
      ? AbortSignal.any([options.signal, timeoutSignal])
      : timeoutSignal;
  }
  const response = await globalThis.fetch(input, options);
  return new Proxy(response, {
    get(target, property) {
      if (property === 'buffer') return async () => Buffer.from(await target.arrayBuffer());
      const value = Reflect.get(target, property, target);
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
}

module.exports = appleFetch;
module.exports.default = appleFetch;
module.exports.Headers = globalThis.Headers;
module.exports.Request = globalThis.Request;
module.exports.Response = globalThis.Response;
