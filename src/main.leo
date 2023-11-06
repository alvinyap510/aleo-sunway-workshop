// The 'token_alyap' program.
program token_alyap.aleo {
    mapping balance: address => u64;

    record Token {
        owner: address,
        amount: u64
    }
    transition mint_private(amount: u64) -> Token{
        return Token {
            owner: self.caller,
            amount: amount
        };
    }

    transition mint_public(amount: u64) {
        return then finalize(amount, self.caller);
    }

    finalize mint_public(amount: u64, caller: address) {
        Mapping::set(balance, caller, amount);
    }

    transition transfer_private(amount: u64, receiver: address, input: Token) -> (Token, Token) {
        let remainder: u64 = input.amount - amount;
        let caller_record: Token = Token {
            owner: self.caller,
            amount: remainder
        };
        let receiver_record: Token = Token {
            owner: receiver,
            amount: amount
        };
        return (caller_record, receiver_record);
    }

    transition transfer_public(amount: u64, receiver: address){
        return then finalize(amount, receiver, self.caller);
    }

    finalize transfer_public(amount: u64, receiver: address, caller: address) {
        let sender_prev_balance: u64 = Mapping::get_or_use(balance, caller, 0u64);
        let receiver_prev_balance: u64 = Mapping::get_or_use(balance, receiver, 0u64);

        assert(sender_prev_balance >= amount);
        let difference: u64 = sender_prev_balance - amount;

        Mapping::set(balance, caller, difference);
        Mapping::set(balance, receiver, difference);
    }

    transition transfer_private_to_public(amount: u64, receiver: address, input: Token) -> Token{
        let remainder: u64 = input.amount - amount;

        let caller: Token = Token {
            owner: self.caller,
            amount: remainder
        };
        return caller then finalize(amount, receiver, self.caller);
    }

    finalize transfer_private_to_public(amount: u64, receiver: address, caller: address){
        let receiver_prev_balance: u64 = Mapping::get_or_use(balance, receiver, 0u64);

        Mapping::set(balance, receiver, amount + receiver_prev_balance);
    }

    transition transfer_public_to_private(amount: u64, receiver: address) -> Token {
        return Token {
            owner: receiver,
            amount: amount,
        } then finalize(amount, self.caller);
    }

    finalize transfer_public_to_private(amount: u64, sender: address) {
        let sender_prev_balance: u64 = Mapping::get_or_use(balance, sender, 0u64);

        Mapping::set(balance, sender, sender_prev_balance - amount);
    }

    transition join(input1: Token, input2: Token) -> Token {
        return Token {
            owner: self.caller,
            amount: input1.amount + input2.amount,
        };
    }
}
