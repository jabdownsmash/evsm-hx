
package evsm;

class FStateGenerator<T: (StateObject),U: (EventObject)> {


    public function new()
    {
    }

    public function newState(?name:String)
    {
        return new FState<T,U>(name);
    }
}