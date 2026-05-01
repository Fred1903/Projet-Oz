functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% =================== BASE FUNCTIONS ===================

    % Returns transaction hash
    fun {TransactionHash Nonce Sender Receiver Value}
        (Nonce + Sender + Receiver + Value) mod 1000000
    end

    % Returns sum of transaction hashes
    fun {SumTransactionsHashes Transactions}
        case Transactions of nil then 
            0
        [] H|T then 
            H.hash + {SumTransactionsHashes T}
        end
    end

    % Returns block hash
    fun {BlockHash Number PreviousHash Transactions}
        (Number + PreviousHash + {SumTransactionsHashes Transactions}) mod 1000000
    end

    % Returns effort of a transaction
    % Example:
    % Value = 500 has 3 digits
    % Effort = 2^0 + 2^1 + 2^2 = 1 + 2 + 4 = 7
    fun {ComputeEffort Value}
        fun {Loop N Accumulator}
            if N == 0 then 
                Accumulator
            else 
                {Loop (N div 10) (2 * Accumulator + 1)}
            end
        end
    in 
        if Value == 0 then 
            1
        else 
            {Loop Value 0}
        end
    end

    % Initial state of blockchain from the genesis record
    % Each balance is converted into a user record with nonce = 0
    fun {InitialState Genesis}
        {Record.map Genesis fun {$ Balance} user(balance:Balance nonce:0) end}
    end

    % Returns a user if he exists, else creates a default user
    fun {GetUser State User}
        if {HasFeature State User} then 
            State.User
        else 
            user(balance:0 nonce:0)
        end
    end

    %% =================== EXTENSION : COST OF EFFORT ===================

    % Check if a transaction is valid
    % The sender must have enough money to pay:
    % transaction value + effort cost
    fun {IsTransactionValid Transaction State}
        Sender = {GetUser State Transaction.sender}
    in
        if Transaction.value < 0 then 
            false
        else
            local Effort in
                Effort = {ComputeEffort Transaction.value}

                if Transaction.nonce \= Sender.nonce + 1 then 
                    false

                elseif Transaction.hash \= {TransactionHash Transaction.nonce Transaction.sender Transaction.receiver Transaction.value} then 
                    false

                elseif Sender.balance < Transaction.value + Effort then 
                    false

                elseif Transaction.max_effort =< 0 then 
                    false 

                elseif Transaction.max_effort < Effort then 
                    false 

                else 
                    true
                end
            end
        end
    end

    % Makes a transaction and updates the state
    % The sender pays the transaction value plus the effort cost
    % The receiver only receives the transaction value
    fun {MakeTransaction Transaction State}  
        Sender = {GetUser State Transaction.sender}
        Receiver = {GetUser State Transaction.receiver}
        Effort = {ComputeEffort Transaction.value}

        NewSender = user(
            balance:Sender.balance - (Transaction.value + Effort)
            nonce:Sender.nonce + 1
        )

        NewReceiver = user(
            balance:Receiver.balance + Transaction.value
            nonce:Receiver.nonce
        )

        StateSender = {Adjoin State {List.toRecord state [Transaction.sender#NewSender]}}
        StateReceiver = {Adjoin StateSender {List.toRecord state [Transaction.receiver#NewReceiver]}}
    in
        StateReceiver
    end

    %% =================== BLOCKCHAIN CONSTRUCTION ===================

    % Filter transactions of a block and update state after each valid transaction
    fun {FilterBlockTransactions Transactions State TotalEffort}
        case Transactions of nil then 
            result(transactions:nil state:State)

        [] H|T then
            if {IsTransactionValid H State} then
                local Effort in
                    Effort = {ComputeEffort H.value}

                    if TotalEffort + Effort > 300 then
                        {FilterBlockTransactions T State TotalEffort}
                    else
                        local 
                            NewState = {MakeTransaction H State}
                            Rest = {FilterBlockTransactions T NewState (TotalEffort + Effort)}
                        in 
                            result(
                                transactions:H|Rest.transactions
                                state:Rest.state
                            )
                        end
                    end
                end
            else 
                {FilterBlockTransactions T State TotalEffort}
            end
        end
    end

    % Gets all consecutive transactions with the same block number
    fun {GetBlockTransactions Transactions BlockNumber}
        case Transactions of nil then 
            nil
        [] H|T then
            if H.block_number == BlockNumber then 
                H|{GetBlockTransactions T BlockNumber}
            else 
                nil
            end
        end
    end

    % Skips all transactions with the same block number
    fun {SkipBlockTransactions Transactions BlockNumber}
        case Transactions of nil then 
            nil
        [] H|T then
            if H.block_number == BlockNumber then 
                {SkipBlockTransactions T BlockNumber}
            else 
                Transactions
            end
        end
    end


    % Takes all transactions, groups them by block and appends valid blocks to blockchain
    fun {AppendToBlockchain Transactions State PreviousHash Blockchain}
        case Transactions of nil then
            result(blockchain:{List.reverse Blockchain} state:State)
        [] H|_ then
            local
                BlockNumber = H.block_number
                BlockTransactions = {GetBlockTransactions Transactions BlockNumber}
                RestTransactions = {SkipBlockTransactions Transactions BlockNumber}
                FilterResult = {FilterBlockTransactions BlockTransactions State 0}
                ValidTransactions = FilterResult.transactions
                NewState = FilterResult.state
            in
                if ValidTransactions == nil then
                    {AppendToBlockchain RestTransactions NewState PreviousHash Blockchain}
                else
                    local 
                        NewBlock = block(
                            number:BlockNumber
                            previousHash:PreviousHash
                            transactions:ValidTransactions
                            hash:{BlockHash BlockNumber PreviousHash ValidTransactions}
                        )
                    in
                        {AppendToBlockchain RestTransactions NewState NewBlock.hash NewBlock|Blockchain}
                    end
                end
            end
        end
    end

    %% =================== DECODE ===================

    % Return the decoded secret message
    fun {Decode Blockchain}
        {DecodeAcc Blockchain ""}
    end

    % Decode each block and accumulate the resulting message
    fun {DecodeAcc Blockchain Acc}
        case Blockchain of nil then 
            Acc
        [] H|T then
            local Hash DecodedHash NewAcc in
                Hash = H.hash
                DecodedHash = {DecodeHash Hash}
                NewAcc = {Append Acc DecodedHash}
                
                {DecodeAcc T NewAcc}
            end
        end
    end

    % Convert the hash to a string before decoding it
    fun {DecodeHash Hash}
        DigitsString = {Int.toString Hash}
    in
        {DecodeHashAcc DigitsString ""}
    end

    % Decode each pair of digits and append the matching character
    fun {DecodeHashAcc Digits Acc}
        case Digits of D1|D2|Rest then
            local Pair ModNumber Number Letter NewAcc in
                Pair = {String.toInt [D1 D2]}
                ModNumber = Pair mod 37

                if ModNumber < 10 then
                    Number = 36
                else
                    Number = ModNumber
                end

                Letter = {DecodeNumberPair Number}
                NewAcc = {Append Acc Letter}

                {DecodeHashAcc Rest NewAcc}
            end
        else
            Acc
        end
    end

    % Map a decoded number to its Sharelock character
    fun {DecodeNumberPair Number}
        if Number >= 10 andthen Number =< 35 then
            [{List.nth "abcdefghijklmnopqrstuvwxyz" (Number - 9)}]
        elseif Number == 36 then
            " "
        else
            ""
        end
    end

    %% =================== ENTRY POINT ===================

    % This function is the starting point of the execution
    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        State = {InitialState GenesisState}
        Result = {AppendToBlockchain Transactions State 0 nil}
    in
        FinalState = Result.state
        FinalBlockchain = Result.blockchain
    end

end