use "net/http"

class iso RouteBuilder
  """
  Creates the set of middleware and handler that is executed based on the
  incomming request path and method.
  """
  let _routes: Array[_Route] iso = recover Array[_Route] end
  let _responder: Responder
  let _base_middlewares: Array[Middleware]
  var _not_found: Handler = _DefaultNotFound

  new iso create(out: OutStream) =>
    """
    Set the base middleware to the default settings.
    """
    _responder = _DefaultResponder(out)
    _base_middlewares = Array[Middleware](1)
    _base_middlewares.push(ResponseTimer)

  new iso base_middleware(responder: Responder,
    mw: Array[Middleware] iso = recover Array[Middleware] end)
  =>
    """
    Define the base middleware and responder.
    """
    _base_middlewares = recover consume mw end
    _responder = responder

  fun ref get(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Route incomming GET requests to path through the given middlewares and
    handler.
    """
    let bms = _base_middlewares.size()
    let ms = recover
      Array[Middleware](bms + middlewares.size())
    end
    for m in _base_middlewares.values() do ms.push(m) end
    for m in middlewares.values() do ms.push(m) end
    let route = _Route("GET", path, handler, consume ms)
    _routes.push(route)

  // TODO other methods
  // TODO not_found

  fun iso build(): Router =>
    """
    Create a router using the predefined routes.
    """
    let nf = _not_found
    let r = _responder
    let mux = _Multiplexer((consume this)._routes, nf, r)
    Router(mux)

class _DefaultNotFound is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response(404, "Not Found")
    res.add_chunk("404: Not Found")
    c.respond(consume req, consume res)
    consume c
