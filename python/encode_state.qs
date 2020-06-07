namespace variationalSolver2 {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    
    // Helper Functions and Original Framework created by "Gheorghiu, Alexandru" <andrugh@caltech.edu>

    // return the square roots of the absolute values of the elements of an array
    function sqrtAll(v: Double[]): Double[] {
        let n = Length(v);
        mutable sqrtV = new Double[n];
        for (i in 0 .. n - 1) {
            set sqrtV w/= i <- Sqrt(AbsD(v[i]));
        }
        return sqrtV;
    }

    // arccos for a fraction
    function arccosFrac(num: Double, denom: Double): Double {
        if (denom <= 1e-10) {
            return 0.;
        }
        return ArcCos(num / denom);
    }

    // reverses the bits in n
    function reverseBinRep(n: Int, numBits: Int): Int {
        let boolRep = IntAsBoolArray(n, numBits);
        return BoolArrayAsInt(boolRep[numBits - 1 .. -1 .. 0]);
    }

    function sum(v: Double[]) : Double {
        let n = Length(v);
        mutable tot = 0.0;
        for (i in 0 .. n - 1) {
            set tot += v[i];
        }
        return tot;
    }

    // Precompute a reverse-cumulative sum to figure out the relative frequency of each sublist
    // Encodes the qubit array in a W state with weighted probabilities corresponding to pattern frequencies for
    // each string of Hamming length 1 (one-hot encoding)
    operation encodeState(x: Double[], qs: Qubit[]) : Unit {
        let x2 = sqrtAll(x);
        let norm = sum(x2);
        mutable x3 = new Double[Length(x)];
        for (i in 0 .. Length(x) - 1) {
            set x3 w/= i <- x2[i] / norm;
        }
        Message($"{x3}");
        encodeStateHelper(x3, qs);
    }

    operation encodeStateHelper(x: Double[], qs: Qubit[]): Unit {
        let n = Length(x);
        mutable vals = new Double[n];
        Ry(2.0 * ArcSin(x[0]), qs[0]);
        let val = Sqrt(1.0 - PowD(x[0], 2.0));
        set vals w/= 0 <- val;
        Message($"Val: {val}");
        for (i in 1 .. n - 1) {
            let theta = 2.0 * ArcSin(x[i] / vals[i - 1]);
            Message($"Theta: {theta}");
            (ControlledOnInt(0, Ry(theta, _)))(qs[0 .. i - 1], qs[i]);
            let val2 = Sqrt(PowD(vals[i - 1], 2.0) - PowD(x[i], 2.0));
            Message($"Val2: {val2}");
            set vals w/= i <- val2;
        }
    }

    // test function for state encoding
    operation testEnc(): Unit {
        let x = [0.4, 0.1, 0.2, 0.3];
        let numQubits = 4;

        using(qs = Qubit[numQubits]) {
            encodeState(x, qs);
            DumpRegister((), qs);
            ResetAll(qs);
        }
    }
    
    // Works exactly like encodeState except encodes the center tile as two reference qubits and two entangled 
    // copies of the same qubit array such that the right tile can be entangled with the first copy and the first
    // reference qubit and the bottom tile can be entangled with the second copy and the second reference qubit
    operation encodeStateCenter(x: Double[], qs: Qubit[]): Unit is Adj + Ctl {
    
    }
        
}