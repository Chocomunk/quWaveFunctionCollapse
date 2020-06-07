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
    operation variationalTileEntangler(qs1: Qubit[], qs2: Qubit[], fit_table: Bool[][][], compare_right: Bool, conflict: Qubit): Unit {
        let numQubits = Length(qs2);
        // Loops over all possible pairs of states (nxn) and entangles using the
        // CCNOT gate if the corresponding position value in the third dimension
        // ("right" in this case) is false
        for (i in 0 .. numQubits - 1){
          for (j in 0 .. numQubits - 1){
            if (compare_right and not fit_table[i][j][1]){
              CCNOT(qs1[i+2], qs2[j], conflict);
            }
            elif (not compare_right and not fit_table[i][j][2]){
              CCNOT(qs1[i+2], qs2[j], conflict);
            }
          }
        }
    }

    // a simple multi-qubit variational circuit
    // Center, right, bottom are probability double vectors corresponding to input tiles
    // fit_table describes which states are not allowed to be next to each other
    // Output: Boolean array counting number of conflicts for each 3-set of tiles passed in
    operation variationalCircuitFull(center: Double[], right: Double[], bottom: Double[], fit_table: Bool[][][]): Int {
        let numQubits = Length(center);
        mutable conflicts = 0;
        using ((qsCenter, qsRight, qsBottom, qConflictRight, qConflictBottom) = 
                (Qubit[numQubits], Qubit[numQubits], Qubit[numQubits], Qubit(), Qubit())) {

            // Encodes and entangle qubit registers
            encodeState(center, qsCenter[numQubits - 1 .. -1 .. 0]);

            if (Length(right) != 0) {
              encodeState(right, qsRight[numQubits - 1 .. -1 .. 0]);
              variationalTileEntangler(qsCenter, qsRight, fit_table, true, qConflictRight);
            }

            if (Length(bottom) != 0) {
              encodeState(bottom, qsBottom[numQubits - 1 .. -1 .. 0]);
              variationalTileEntangler(qsCenter, qsBottom, fit_table, false, qConflictBottom);
            }

            // Observe conflict registers
            if (Length(right) != 0) {
              if (M(qConflictRight) == One) {
                set conflicts += 1;
              }
            }

            if (Length(bottom) != 0) {
              if (M(qConflictBottom) == One) {
                set conflicts += 1;
              }
            }

            // Reset all qubit arrays
            ResetAll(qsCenter);
            ResetAll(qsRight);
            ResetAll(qsBottom);
            Reset(qConflictRight);
            Reset(qConflictBottom);
        }
        return conflicts;
    }

    // Same encoding as the full circuit, but observes waves directly and manually
    // checks conflicts rather than observing conflicts into a register.
    operation variationalCircuitPartial(center: Double[], right: Double[], bottom: Double[], fit_table: Bool[][][]): Int {
        let numQubits = Length(center);
        mutable conflicts = 0;
        using ((qsCenter, qsRight, qsBottom) = (Qubit[numQubits], Qubit[numQubits], Qubit[numQubits])) {

            // Encodes qubit registers
            encodeState(center, qsCenter[numQubits - 1 .. -1 .. 0]);

            if (Length(right) != 0) {
              encodeState(right, qsRight[numQubits - 1 .. -1 .. 0]);
            }

            if (Length(bottom) != 0) {
              encodeState(bottom, qsBottom[numQubits - 1 .. -1 .. 0]);
            }

            // Observe tile states
            mutable k_c = -1;
            mutable k_r = -1;
            mutable k_b = -1;
            for (i in 0 .. numQubits - 1) {
              if (M(qsCenter[i]) == One) {
                set k_c = i;
              }
              if (Length(right) != 0 and M(qsRight[i]) == One) {
                set k_r = i;
              }
              if (Length(bottom) != 0 and M(qsBottom[i]) == One) {
                set k_b = i;
              }
            }

            // Count conflicts given the observed states
            if (Length(right) != 0 and not fit_table[k_c][k_r][1]) {
              set conflicts += 1;
            }

            if (Length(bottom) != 0 and not fit_table[k_c][k_b][2]) {
              set conflicts += 1;
            }

            // Reset all qubit arrays
            ResetAll(qsCenter);
            ResetAll(qsRight);
            ResetAll(qsBottom);
        }
        return conflicts;
    }

}
