namespace variationalSolver {

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

    // Precompute a reverse-cumulative sum to figure out the relative frequency of each sublist
    // Encodes the qubit array in a W state with weighted probabilities corresponding to pattern frequencies for
    // each string of Hamming length 1 (one-hot encoding)
    operation encodeState(x: Double[], qs: Qubit[]): Unit is Adj + Ctl {
    
    }
    
    // Works exactly like encodeState except encodes the center tile as two reference qubits and two entangled 
    // copies of the same qubit array such that the right tile can be entangled with the first copy and the first
    // reference qubit and the bottom tile can be entangled with the second copy and the second reference qubit
    operation encodeStateCenter(x: Double[], qs: Qubit[]): Unit is Adj + Ctl {
    
    }

    
    //  entangle matching index qubits and a corresponding reference qubit between the qubit arrays 
    // to be checked using the CCNOT gate
    // tileFlag: True indicates checking with the "right" tile, False indicates checking with the "bottom" tile
    // posFlag: True indicates the compared tile exists, False indicates an edge case tile where the compared tile
    //          does not exist
    operation variationalTileEntangler(qs1: Qubit[], qs2: Qubit[], tileFlag: Bool, posFlag: Bool): Unit {
        let numQubits = Length(qs2);
        for (i in 0 .. numQubits - 1) {
            // Checks which tile is being compared to center ("right" in this case)
            if (tileFlag){
                // Checks whether the compared ("right" in this case) tile exists 
                // (handles edge cases on the nxn output space)
                if (posFlag) {
                    CCNOT(qs1[i+2], qs2[i], qs1[0]); ;   
                }
            }
            else {
                if (posFlag) {
                    CCNOT(qs1[i+numQubits+2], qs2[i], qs1[1]);
                } 
            }
        }
    }

    // a simple multi-qubit variational circuit
    // Center, right, bottom are probability double vectors corresponding to input tiles
    // fit_table is a double array corresponding to the bit string input patterns
    // Output: Boolean array counting number of conflicts for each 3-set of tiles passed in
    operation variationalCircuit(center: Double[], right: Double[], bottom: Double[], fit_table: Double[]): Bool[] {
        let numQubits = Length(center);
        mutable rightPosFlag = true;
        mutable bottomPosFlag = true;
        mutable conflicts = new Bool[2];
        using ((qsCenter, qsRight, qsBottom) = (Qubit[2*(numQubits + 1)], Qubit[numQubits], Qubit[numQubits])) {
            let refCenterQs = qsCenter[2 .. 2*numQubits];
            let refRightQs = qsRight[0 .. numQubits];
            let refBottomQs = qsBottom[0 .. numQubits];
            
            // Encodes tiles into W states with appropriate weighted probabilities
            encodeStateCenter(center, refCenterQs[2*numQubits - 1 .. -1 .. 0]);
            encodeState(right, refRightQs[numQubits - 1 .. -1 .. 0]);
            encodeState(bottom, refBottomQs[numQubits - 1 .. -1 .. 0]);
                
            // Edge tile cases have at least one input double array with length 0 corresponding to the missing
            // tile ("right" in this case)
            if (Length(right) != 0){
                variationalTileEntangler(qsCenter, qsRight, true);
                // Measure the (first) reference qubit to determine if there is any conflicts between the center
                // tile and the compared tile ("right" in this case)
                // Appends a Boolean value for each check to be passed out back into the classical loss function
                if (M(qsCenter[0]) == One){
                    set conflicts w/= 0 <- true;
                }
                else{
                    set conflicts w/= 0 <- false;
                }
            }
            else{
                set conflicts w/= 0 <- false;
            }
            if (Length(bottom) != 0){
                variationalTileEntangler(qsCenter, qsBottom, true);
                if (M(qsCenter[0]) == One){
                    set conflicts w/= 1 <- true;
                }
                else{
                    set conflicts w/= 1 <- false;
                }
            }
            else{
                set conflicts w/= 1 <- false;
            }
            // Reset all qubit arrays
            ResetAll(qsCenter);
            ResetAll(qsRight);
            ResetAll(qsBottom);
        }
        return conflicts;
    }
        
}