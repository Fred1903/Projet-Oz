functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% STUDENT START:
    
    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED

    % Returns transition Hash
    fun {TransitionHash Nonce Sender Receiver Value}
         (Nonce + Sender + Receiver + Value) mod 1000000
    end

    % Returns sum of transition Hashes
    fun {SumTransactionsHashes Transactions}
        case Transactions of nil then 0
        [] H|T then H.hash + {SumTransactionsHashes T}
        end
    end

    % Returns block hash
    fun {BlockHash Number PreviousNumber Transactions}
        (Number + PreviousNumber + {SumTransactionsHashes Transactions}) mod 1000000
    end

    % Returns effort of a transaction
    % Ex: Effort for 500 (N=length=3)=Sum(2^0 to N-1)= 2^0 + 2^1 + 2^2 = 1+2+4=7
    % --> Sum = 2^n-1 --> 2^3-1 = 7 
    % Acc : Sum n+1= 2 * Sum n +1 
    fun {ComputeEffort Value}
        fun {Loop N Accumulator}
            if N==0 then Accumulator
            else {Loop N div 10 2*Accumulator+1}
            end
        end
    in 
        {Loop Value 0}
    end


    % Initial state of blockchain from the genesis record
    % Each balance is converted into a user record with a nonce=0
    % Function written with help of AI
    fun {InitialState Genesis}
        {Record.map Genesis fun {$ Balance} user(balance: Balance nonce:0)end}
    end


    fun{IsTransactionValid Transaction State}
    
    end

    
    fun{MakeTransaction Transaction State}  
    
    end


    fun {ProcessTransactions Transactions State}
    case Transactions of nil then 
        State
    [] H|T then 
        if {IsTransactionValid Transaction State} then
            NewState = {MakeTransaction Transaction State}
        in 
            {ProcessTransactions T NewState}
        else 
            {ProcessTransactions T State}
        end
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
        State = {InitialState GenesisState}
        %% STUDENT END
    end
end