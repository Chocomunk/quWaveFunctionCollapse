namespace quwfc {

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

    // reverses the bits in n
    function reverseBinRep(n: Int, numBits: Int): Int {
        let boolRep = IntAsBoolArray(n, numBits);
        return BoolArrayAsInt(boolRep[numBits - 1 .. -1 .. 0]);
    }

    // Encodes the probabilities from the x array into a superposition, where
    // the square roots of the probabilities given are the amplitudes of the 
    // superposition
    operation encodeState(x: Double[], qs: Qubit[]) : Unit {
        let x2 = sqrtAll(x);
        encodeStateHelper(x2, qs);
    }

    // Main function for encoding, this uses ideas similar to the Quantum Katas
    // in generating the W state using controlled y rotations.
    // This also uses trigonometry to compute the correct angle to rotate by
    // in order for the amplitude to be correct. This directly takes the values in x and 
    // encodes them as the amplitudes of the superposition
    operation encodeStateHelper(x: Double[], qs: Qubit[]): Unit {
        let n = Length(x);
        // table of values to hold intermediate values
        mutable vals = new Double[n];
        Ry(2.0 * ArcSin(x[0]), qs[0]);
        // use Pythagorean Theorem to calculate value on |0000> state after rotation
        let val = Sqrt(1.0 - PowD(x[0], 2.0));
        // store value for later use
        set vals w/= 0 <- val;
        for (i in 1 .. n - 1) {
            // rotate by specific angle
            // dividing by vals[i - 1] cancels out amplitude on |0000> from previous rotation
            let theta = 2.0 * ArcSin(x[i] / vals[i - 1]);
            // control on all qubits before being in zero state to not affect superposition
            // we've already created
            (ControlledOnInt(0, Ry(theta, _)))(qs[0 .. i - 1], qs[i]);
            // stores the next value to be stored, again calculated using Pythagorean Theorem
            let val2 = Sqrt(PowD(vals[i - 1], 2.0) - PowD(x[i], 2.0));
            set vals w/= i <- val2;
        }
    }

    // test function for state encoding
    operation testEnc(): Unit {
        // can be changed as long as probabilities add to 1
        let x = [0.4, 0.1, 0.2, 0.3];
        let numQubits = Length(x);

        using(qs = Qubit[numQubits]) {
            encodeState(x, qs);
            // shows the superposition
            DumpRegister((), qs);
            ResetAll(qs);
        }
    }
    
    // Works exactly like encodeState except encodes the center tile as two reference qubits and two entangled 
    // copies of the same qubit array such that the right tile can be entangled with the first copy and the first
    // reference qubit and the bottom tile can be entangled with the second copy and the second reference qubit
    // First two qubits in qs are reference qubits, the rest is divided into two halves to implement the idea 
    // described above
    operation encodeStateCenter(x: Double[], qs: Qubit[]): Unit {
        let n = Length(qs);
        let centerQs = qs[2 .. n - 1];
        encodeState(x, qs[2 .. n / 2]);
        encodeState(x, qs[n / 2 + 1 .. n - 1]);
    }
}