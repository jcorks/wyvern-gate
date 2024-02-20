@:Topaz = import(module:'Topaz');
return ::(terminal, name, onCompute) {

    // Careful! if you remove this, people could do all sorts of things
    @:nameFiltered = name->replace(keys:['/', '\\', '..'], with: '');
    {:::} {
        onCompute(result:import(module:nameFiltered));
    } : {
        onError::(message) {
            when (message->type == String) ::<= {
                onCompute(result:'An error occurred: ' + message);
            }

            when (message->type == Object) ::<= {
                onCompute(result:message.summary);
            }
        }
    }
}
