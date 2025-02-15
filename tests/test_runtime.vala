

//  Reference: https://gitlab.gnome.org/partizan/geary
public class AsyncResultWaiter : GLib.Object {
    /** The main loop that is executed when waiting for async results. */
    public GLib.MainContext main_loop { get; construct set; }

    private GLib.AsyncQueue<GLib.AsyncResult> results =
        new GLib.AsyncQueue<GLib.AsyncResult>();


    /**
     * Constructs a new waiter.
     *
     * @param main_loop a main loop context to execute when waiting
     * for an async result
     */
    public AsyncResultWaiter(GLib.MainContext main_loop) {
        Object(main_loop: main_loop);
    }

    /**
     * The last argument of an async call to be tested.
     *
     * Records the given {@link GLib.AsyncResult}, adding it to the
     * internal FIFO queue. This method should be called as the
     * completion of an async call to be tested.
     *
     * To use it, pass as the last argument to the `begin()` form of
     * the async call:
     *
     * {{{
     *     var waiter = new AsyncResultWaiter();
     *     my_async_call.begin("foo", waiter.async_completion);
     * }}}
     */
    public void async_completion(GLib.Object? object,
                                 GLib.AsyncResult result) {
        this.results.push(result);
        // Notify the loop so that if async_result() has already been
        // called, that method won't block.
        this.main_loop.wakeup();
    }

    /**
     * Waits for async calls to complete, returning the most recent one.
     *
     * This returns the first {@link GLib.AsyncResult} from the
     * internal FIFO queue that has been provided by {@link
     * async_completion}. If none are available, it will pump the main
     * loop, blocking until one becomes available.
     *
     * To use it, pass its return value as the argument to the `end()`
     * call:
     *
     * {{{
     *     my_async_call.end(waiter.async_result());
     * }}}
     */
    public GLib.AsyncResult async_result() {
        GLib.AsyncResult? result = this.results.try_pop();
        while (result == null) {
            this.main_loop.iteration(true);
            result = this.results.try_pop();
        }
        return (GLib.AsyncResult) result;
    }

}
