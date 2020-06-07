import qsharp
from quwfc import testEnc, variationalCircuitPartial, variationalCircuitFull


def test_encoding():
    print("Encoding Test")
    testEnc.simulate()
    print("")


def test_variational():
    print("VQE Test")
    # Two states A and B. They can only be next to the other state, not themselves.
    fit_table = [[[False, False, False, False],[True,True,True,True]], 
                 [[True, True, True, True],[False,False,False,False]]]

    #  Only A states
    # res1_f = variationalCircuitFull.simulate(center=[.99,0.01], right=[.99,0.01], 
    #     bottom=[.99,0.01], fit_table=fit_table)
    res1_p = variationalCircuitPartial.simulate(center=[.99,0.01], right=[.99,0.01], 
        bottom=[.99,0.01], fit_table=fit_table)
    print("Only A conflicts: {}".format(res1_p))

    #  A surrounded by B
    # res2_f = variationalCircuitFull.simulate(center=[.99,0.01], right=[0.01,.99], 
    #     bottom=[0.01,.99], fit_table=fit_table)
    res2_p = variationalCircuitPartial.simulate(center=[.99,0.01], right=[0.01,.99], 
        bottom=[0.01,.99], fit_table=fit_table)
    print("B around A conflicts: {}".format(res2_p))

    # Superposition
    # res3_f = variationalCircuitFull.simulate(center=[0.5,0.5], right=[0.5,0.5], 
    #     bottom=[0.5,0.5], fit_table=fit_table)
    res3_p = variationalCircuitPartial.simulate(center=[0.5,0.5], right=[0.5,0.5], 
        bottom=[0.5,0.5], fit_table=fit_table)
    print("Superposition conflicts: {}".format(res3_p))


if __name__ == "__main__":
    test_encoding()
    test_variational()
