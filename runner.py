from Model import *
import cv2
import argparse


def main(tile_dir, is_quantum, dim, out_shape, img_shape, qrng):
    # Can change second argument to make ouput image larger
    model = Model(tile_dir, out_shape, dim, rotate_patterns=True, iteration_limit=-1)

    if False:
        break_all = False
        print()

        for p_i_1 in range(model.num_patterns):
            scaled1 = cv2.resize(model.patterns[p_i_1], (128, 128), interpolation=cv2.INTER_AREA)
            for p_i_2 in range(model.num_patterns):
                scaled2 = cv2.resize(model.patterns[p_i_2], (128, 128), interpolation=cv2.INTER_AREA)
                comb = np.hstack((scaled1, np.full((128, 10, 3), 128), scaled2))
                print("template: {}, conv: {}, result:\n{}\n{}\n".format(p_i_1, p_i_2, model.fit_table[p_i_1,p_i_2], model.overlays))
                cv2.imshow("comparison", comb/255.0)
                k = cv2.waitKey(0)
                if k == 27:
                    break_all = True
                    break
                elif k == ord('n'):
                    break
            if break_all:
                break

    # Generates the image using the variational approach
    # Can change to model.generate_classical() with the flag for qrng to
    # change method used to generate the output image
    if is_quantum:
        model.generate_variational()
    else:
        model.generate_classical(qrng)

    # Resizing and displaying output image
    result = cv2.resize(model.out_img, img_shape, interpolation=cv2.INTER_AREA)
    cv2.imshow("result", result/255.0)
    cv2.waitKey(0)
    cv2.imwrite("{}/results/python/result.png".format(tile_dir), result)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tiledir", type=str, default="tiles/red",
            help="Directory to folder storing template image")
    parser.add_argument("--dim", type=int, default=2,
            help="Dim 'd' of patterns. Every pattern/state is a dxd section \
            of the template image.")
    parser.add_argument("--outwidth", type=int, default=3,
            help="Width in pixels of the generated output.")
    parser.add_argument("--outheight", type=int, default=3,
            help="Height in pixels of the generated output.")
    parser.add_argument("--imgwidth", type=int, default=300,
            help="Width in pixels of the rendered image.")
    parser.add_argument("--imgheight", type=int, default=300,
            help="Height in pixels of the rendered image.")
    parser.add_argument("--qrng", action="store_true", 
            help="Whether to use quantum random numbers in the classical algorithm.")
    parser.add_argument("algorithm_type", type=str, choices=["quantum", "classical"],
            help="Selects either the quantum VQE algorithm or classical propagator.")
    args = parser.parse_args()

    main(args.tiledir, args.algorithm_type == "quantum", args.dim, 
        (args.outwidth, args.outheight), (args.imgwidth, args.imgheight), args.qrng)
