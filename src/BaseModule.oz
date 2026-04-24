functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% STUDENT START:
    
    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED


    fun {TransitionHash Nonce Sender Receiver Value}
         (Nonce + Sender + Receiver + Value) mod 1000000
    end

    fun {SumTransactionsHashes Transactions}
        case Transactions of nil then 0
        [] H|T then H.hash + {SumTransactionsHashes T}
        end
    end

    fun {BlockHash Number PreviousNumber Transactions}
        (Number + PreviousNumber + {SumTransactionsHashes Transactions}) mod 1000000
    end

    %% STUDENT END
 
    %% Return a string representation of the secret
    fun {Decode Blockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
    end


    % ATTENTION; SUR FORUM YA MARQUÉ QUE FAUT REMPLACER FUN PAR PROC ICI
    % --> a VOIR QUAND ON IMPLÉMENTE

    % This function is the starting point of the execution
    % The GenesisState and the Transactions are given as input and the function is expected to bound the FinalState and the FinalBlockchain to their respective final values.
    fun {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
    end
end