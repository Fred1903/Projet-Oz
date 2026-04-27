functor
import
    Browser
    System
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% STUDENT START:
    
    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED

    % Returns transaction hash
    fun {TransactionHash Nonce Sender Receiver Value}
         (Nonce + Sender + Receiver + Value) mod 1000000
    end

    % Returns sum of transaction hashes
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
    fun {ComputeEffort Value}
        fun {Loop N Accumulator}
            if N == 0 then Accumulator
            else {Loop N div 10 2 * Accumulator + 1}
            end
        end
    in 
        if Value == 0 then 1
        else {Loop Value 0}
        end
    end

    % Initial state of blockchain from the genesis record
    fun {InitialState Genesis}
        {Record.map Genesis fun {$ Balance} user(balance:Balance nonce:0) end}
    end

    % Returns a user if it exists, otherwise returns a default user
    fun {GetUser State User}
        if {HasFeature State User} then State.User
        else user(balance:0 nonce:0)
        end
    end

    % Checks if a transaction is valid
    fun {IsTransactionValid Transaction State}
        Sender = {GetUser State Transaction.sender}
    in
        if Transaction.nonce \= Sender.nonce + 1 then false
        elseif Transaction.hash \= {TransactionHash Transaction.nonce Transaction.sender Transaction.receiver Transaction.value} then false
        elseif Sender.balance < Transaction.value then false
        elseif Transaction.value < 0 then false
        elseif Transaction.max_effort =< 0 then false 
        elseif Transaction.max_effort < {ComputeEffort Transaction.value} then false 
        else true
        end
    end

    % Applies a transaction and updates the state
    fun {MakeTransaction Transaction State}  
        Sender = {GetUser State Transaction.sender}
        Receiver = {GetUser State Transaction.receiver}

        NewSender = user(
            balance:Sender.balance - Transaction.value
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

    % Filters valid transactions of a block and updates the state
    fun {FilterBlockTransactions Transactions State TotalEffort}
        case Transactions of nil then 
            result(transactions:nil state:State)

        [] H|T then 
            local 
                Effort = {ComputeEffort H.value}
            in
                if TotalEffort + Effort > 300 then
                    {FilterBlockTransactions T State TotalEffort}

                elseif {IsTransactionValid H State} then
                    local 
                        NewState = {MakeTransaction H State}
                        Rest = {FilterBlockTransactions T NewState TotalEffort + Effort}
                    in 
                        result(transactions:H|Rest.transactions state:Rest.state)
                    end

                else 
                    {FilterBlockTransactions T State TotalEffort}
                end
            end
        end
    end

    % Gets all transactions with the same block number
    fun {GetBlockTransactions Transactions BlockNumber}
        case Transactions of nil then nil
        [] H|T then
            if H.block_number == BlockNumber then
                H | {GetBlockTransactions T BlockNumber}
            else
                nil
            end
        end
    end

    % Skips all transactions with the same block number
    fun {SkipBlockTransactions Transactions BlockNumber}
        case Transactions of nil then nil
        [] H|T then
            if H.block_number == BlockNumber then
                {SkipBlockTransactions T BlockNumber}
            else
                Transactions
            end
        end
    end

    % Appends a block to the blockchain
    fun {AppendBlock Blockchain NewBlock}
        case Blockchain of nil then [NewBlock]
        [] H|T then H | {AppendBlock T NewBlock}
        end
    end

    % Groups transactions by block and builds the blockchain
    fun {AppendToBlockchain Transactions State PreviousHash Blockchain}
        case Transactions of nil then
            result(blockchain:Blockchain state:State)

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
                        {AppendToBlockchain RestTransactions NewState NewBlock.hash {AppendBlock Blockchain NewBlock}}
                    end
                end
            end
        end
    end
 
    %% Return the decoded secret message
    fun {Decode Blockchain}
        {DecodeAcc Blockchain ""}
    end

    %% Decode each block and accumulate the resulting message
    fun {DecodeAcc Blockchain Acc}
        case Blockchain of nil then Acc
        [] H|T then
            local Hash DecodedHash NewAcc in
                Hash = H.hash
                DecodedHash = {DecodeHash Hash}
                NewAcc = {Append Acc DecodedHash}
                
                {DecodeAcc T NewAcc}
            end
        end
    end

    %% Convert the hash to a string before decoding it
    fun {DecodeHash Hash}
        DigitsString = {Int.toString Hash}
    in
        {DecodeHashAcc DigitsString ""}
    end

    %% Decode each pair of digits and append the matching character
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

    %% Map a decoded number to its Sharelock character
    fun {DecodeNumberPair Number}
        if Number >= 10 andthen Number =< 35 then
            [{List.nth "abcdefghijklmnopqrstuvwxyz" Number - 9}]
        elseif Number == 36 then
            " "
        else
            ""
        end
    end

    %% STUDENT END

    %%% =================== EXTENSIONS =================== 

    %% 3. STATS

    % Returns a list of N users which have made most of the validated transactions
    fun {BiggestSenders Blockchain N}
        Counts = {ApplyTransactionsBlockchain Blockchain nil IncrementSenderTransactionCount}
        Sorted = {SortNumberDescending Counts}
    in
        if N <= 0 then
            -1
        else
            {Take N Sorted}
        end
    end

    % Loop over the list of blocks of the blockchain
    fun {ApplyTransactionsBlockchain Blockchain Acc F}
        case Blockchain of nil then
            Acc
        [] H|T then
            local NewAcc in
                NewAcc = {ApplyTransactions H.transactions Acc F}
                {ApplyTransactionsBlockchain T NewAcc F}
            end
        end
    end

    % Loop over the list of transactions of a block
    fun {ApplyTransactions Transactions Acc F}
        case Transactions of nil then
            Acc
        [] H|T then
            local NewAcc in
                NewAcc = {F H Acc}
                {ApplyTransactions T NewAcc F}
            end
        end
    end

    % Update the transaction count for the sender
    fun {IncrementSenderTransactionCount Transaction Counts}
        Sender = Transaction.sender
    in
        case Counts of nil then
            [Sender#1]
        [] (User#Count)|T then
            if User == Sender then
                (User#(Count+1))|T
            else
                (User#Count)|{IncrementSenderTransactionCount Transaction T}
            end
        end
    end

    % Take the N first transactions counts of the list
    fun {Take N SortedCounts}
        if N == 0 then 
            nil
        else
            case SortedCounts of nil then 
                nil
            [] H|T then
                H | {Take (N-1) T}
            end
        end
    end

    % Sort list of user with numerical value
    fun {SortNumberDescending Counts}
        case Counts of nil then
            nil
        [] H|T then
            {InsertSortNumberDescending H {SortNumberDescending T}}
        end
    end

    % Insertion sort
    fun {InsertSortNumberDescending Elem Sorted}
        case Sorted of nil then
            [Elem]
        [] H|T then
            case Elem of User1#Count1 then
                case H of User2#Count2 then
                    if Count1 >= Count2 then
                        Elem|Sorted
                    else
                        H|{InsertSortNumberDescending Elem T}
                    end
                end
            end
        end
    end

    % Returns a list of N users having received the highest total amount
    fun {ReceivedMost Blockchain N}
        Balances = {ApplyTransactionsBlockchain Blockchain nil IncrementReceiverBalance}
        Sorted = {SortNumberDescending Balances}
    in
        if N <= 0 then
            -1
        else
            {Take N Sorted}
        end
    end

    % Update the received amount for the receiver
    fun {IncrementReceiverBalance Transaction Balances}
        Receiver = Transaction.receiver
        Value = Transaction.value
    in
        case Balances of nil then
            [Receiver#Value]
        [] (User#Balance)|T then
            if User == Receiver then
                (User#(Balance+Value))|T
            else
                (User#Balance)|{IncrementReceiverBalance Transaction T}
            end
        end
    end

    % Returns a user who has the highest amount of money at a certain time in the blockchain
    fun {MoneyPeak Blockchain}
        {MoneyPeakAcc Blockchain 0}
    end

    % Recursive function looking for a new max
    fun {MoneyPeakAcc Blockchain MaxUserAmount}

    end

    % Takes a user object and add the amount to its balance
    fun {UpdateReceiver Receiver}

    end

    % Takes a user object and retrieve the amount to its balance
    fun {UpdateSender Sender}

    end

    % This function is the starting point of the execution
    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        State = {InitialState GenesisState}
        Result = {AppendToBlockchain Transactions State 0 nil}
        AltruistsUsers
        NRichUsers
        RichUser
    in
        FinalState = Result.state
        FinalBlockchain = Result.blockchain

        AltruistsUsers = {BiggestSenders FinalBlockchain 5}
        NRichUsers = {ReceivedMost FinalBlockchain 3}
        RichUser = {MoneyPeak FinalBlockchain}

        {System.show AltruistsUsers}
        {System.show NRichUsers}
        {System.show RichUser}
    end
end