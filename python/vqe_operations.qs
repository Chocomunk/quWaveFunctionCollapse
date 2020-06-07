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

    // entangle qubits and a corresponding reference qubit using the CCNOT gate
    // using the fit_table array of acceptable neighboring states
    operation variationalTileEntangler(qs1: Qubit[], qs2: Qubit[], fit_table: Bool[][][]): Unit {
        let numQubits = Length(qs2);
        // Loops over all possible pairs of states (nxn) and entangles using the
        // CCNOT gate if the corresponding position value in the third dimension
        // ("right" in this case) is false
        for (i in 0 .. numQubits - 1){
          for (j in 0 .. numQubits - 1){
            if (Not(fit_table[i][j][1])){
              CCNOT(qs1[i+2], qs2[j], qs1[0]);
            }
            elif (Not(fit_table[i][j][2])){
              CCNOT(qs1[i+numQubits+2], qs2[j], qs1[1]);
            }
          }
        }
    }

    // a simple multi-qubit variational circuit
    // Center, right, bottom are probability double vectors corresponding to input tiles
    // fit_table describes which states are not allowed to be next to each other
    // Output: Boolean array counting number of conflicts for each 3-set of tiles passed in
    operation variationalCircuit(center: Double[], right: Double[], bottom: Double[], fit_table: Bool[][][]): Bool[] {
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
            if (Length(right) != 0) {
              variationalTileEntangler(qsCenter, qsRight, fit_table);
              // Measure the (first) reference qubit to determine if there is any conflicts between the center
              // tile and the compared tile ("right" in this case)
              // Appends a Boolean value for each check to be passed out back into the classical loss function
              if (M(qsCenter[0]) == One) {
                set conflicts w/= 0 <- true;
              }
              else {
                set conflicts w/= 0 <- false;
              }
            }
            else {
              set conflicts w/= 0 <- false;
            }

            if (Length(bottom) != 0) {
              variationalTileEntangler(qsCenter, qsBottom, fit_table);
              if (M(qsCenter[0]) == One) {
                set conflicts w/= 1 <- true;
              }
              else {
                set conflicts w/= 1 <- false;
              }
            }
            else {
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
