namespace qrng {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;

    // Returns a random Result (One or Zero), interpreted as a random bit
    operation randomBit() : Result {
        mutable res = Zero;
        using (q = Qubit()) {
            // Transforms |0> into |+>, equal superposition of |0> and |1>
            H(q);
            // Measuring in computational basis to arrive at random Result
            set res = MResetZ(q);
        }
        return res;
    }
    
    // Uses the randomBit() to generate a random integer between 0 and bound
    operation randomInt(bound : Int) : Int {
        // To store random integer to be returned
        mutable ret = bound + 1;
        // Finds the number of bits needed to represent bound number
        let bitLength = Ceiling(Lg(IntAsDouble(bound)));
        // Until we generate a random number within the bound
        repeat {
            mutable bits = new Result[bitLength];
            // Creating bit string of random bits
            for (i in 0 .. bitLength - 1) {
                set bits w/= i <- randomBit();
            }
            set ret = ResultArrayAsInt(bits);
        } until (ret <= bound);
        return ret;
    }
}