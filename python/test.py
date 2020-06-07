from Model import *
import cv2

# Directory that the test images are in
tile_dir = "../tiles/red"

# Can change second argument to make ouput image larger
model = Model(tile_dir, (4, 4), 2, rotate_patterns=True, iteration_limit=-1)

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
model.generate_variational()

# Resizing and displaying output image
result = cv2.resize(model.out_img, (256, 256), interpolation=cv2.INTER_AREA)
cv2.imshow("result", result/255.0)
cv2.waitKey(0)
cv2.imwrite("{}/results/python/result.png".format(tile_dir), result)
