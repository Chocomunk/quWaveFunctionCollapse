namespace qrng {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;

    // 
    operation randomBit() : Result {
        mutable res = Zero;
        using (q = Qubit()) {
            H(q);
            set res = MResetZ(q);
        }
        return res;
    }

    operation randomInt(bound : Int) : Int {
        mutable ret = bound + 1;
        let bitLength = Ceiling(Lg(IntAsDouble(bound)));
        repeat {
            mutable bits = new Result[bitLength];
            for (i in 0 .. bitLength - 1) {
                set bits w/= i <- randomBit();
            }
            set ret = ResultArrayAsInt(bits);
        } until (ret <= bound);
        return ret;
    }
}