import numpy as np
import random
import Input

import qsharp
from quwfc import variationalCircuit, randomInt
from scipy.optimize import minimize

# Calculates the entropy for a given probability
def entropy_b2(prob):
    return -prob*np.log2(prob)


# Top, Right, Bottom, Left
_overlays = [(-1, 0), (0, 1), (1, 0), (0, -1)]


def generate_sliding_overlay(dim):
    _overlay = []
    for i in range(1-dim, dim):
        for j in range(1-dim, dim):
            if i is not 0 or j is not 0:
                _overlay.append((i, j))
    return _overlay

# Loss function for the variational approach
# The fit table is K x K x 4 table where K is the number of states
# The 4 dimension comes from each of the 4 adjacent state directions
# this holds the constraints on neighboring states.
# The probabilities for each tile being in a certain state are given in probs.

def loss_function(shape, probs, fit_table, qruns=10):
    rows = shape[0]
    cols = shape[1]
    patts = shape[2]
    probs = np.reshape(probs, shape).tolist()

    print(probs)
    print(fit_table)

    loss = 0
    # iterate through all possible center tiles to calculate total number of
    # conflicts with the constraints
    for r in range(rows):
        for c in range(cols):
            center = probs[r][c]
            right = probs[r][c+1] if c+1 < cols else []
            bottom = probs[r+1][c] if r+1 < rows else []
            # Run the quantum circuit to get the number of conflicts for
            # a given center tile
            res = variationalCircuit.simulate(center=center, right=right, 
                bottom=bottom, fit_table=fit_table)
            print(res)
            # loss += np.sum(res)
    print("Total Conflicts: {}".format(loss))
    return loss


class Model:

    # Initialize everything
    def __init__(self, tile_dir, output_shape, dim, rotate_patterns=False, iteration_limit=-1, overlays=_overlays):
        self.tiles = Input.load_tiles(tile_dir)
        self.img_shape = output_shape
        self.dim = dim
        self.rotate_patterns = rotate_patterns
        self.iteration_limit = iteration_limit
        self.overlays = overlays

        self.patterns = []
        self.counts = []
        self.fit_table = []
        self.propagate_stack = []
        self.probs = None

        self.create_waveforms(dim)

        self.num_patterns = len(self.patterns)
        self.wave_shape = (self.img_shape[0]+1 - dim, self.img_shape[1]+1 - dim)

        self.check_fits()

        self.waves = np.full(self.wave_shape + (self.num_patterns,), True)
        self.observed = np.full(self.wave_shape, False)
        self.registered_propogate = np.full(self.wave_shape, False)
        # self.entropies = np.full(self.wave_shape, -np.sum(self.probs * np.log2(self.probs)))
        self.entropies = np.ones(self.wave_shape, dtype=np.int16)*self.num_patterns
        self.out_img = np.full(self.img_shape + (3,), -1.)

        print(self.fit_table.shape)
        print(self.wave_shape)
        print(self.waves.shape)

    # Generates the output image using the variational approach
    def generate_variational(self, qruns=10):
        shape = self.wave_shape + (self.num_patterns,)
        params_init = np.tile(self.probs, self.wave_shape + (1,)).flatten()
        bounds = np.tile((0,1), (len(params_init), 1))
        # wrapper function for our loss function
        loss_func = lambda params: loss_function(shape, params, self.fit_table.tolist(), qruns)
        # minimizer to choose the tile probabilities with least conflicts
        res = minimize(loss_func, params_init, method='L-BFGS-B', 
            options={'disp': True, 'maxiter': 20}, bounds=bounds)
        if res.success:
            result = res.x
            for r in range(self.wave_shape[0]):
                for c in range(self.wave_shape[1]):
                    best_patt = np.argmax(result[r][c])
                    self.do_observe(r, c, best_patt)
                    self.render_superpositions(r, c)
        else:
            print("ERROR: Optimization failed!")
        
    # Generates the output image using the completely classical/qrng approach
    # Flag qrng indicates whether or not we use qrng to select the initial
    # superposition and the state to collapse
    def generate_classical(self, qrng=False):
        row, col = 0, 0
        # Use Python's random module or not depending on flag
        if not qrng:
            row, col = random.randint(0, self.wave_shape[0]-1), random.randint(0, self.wave_shape[1]-1)
        else:
            # Use quantum random number generation
            row = randomInt.simulate(bound=self.wave_shape[0] - 1)
            col = randomInt.simulate(bound=self.wave_shape[1] - 1)

        # Standard WFC Loop:
        # 1. Observe a wave and collapse its state
        # 2. Propagate the changes throughout the board and update superposition
        #    to only allowed states.
        # 3. After the board state has stabilized, find the position of lowest
        #    entropy (most likely to be observed) for the next observation.
        iteration = 0
        while row >= 0 and col >= 0 and (self.iteration_limit<0 or iteration<self.iteration_limit):
            self.observe_wave(row, col, qrng)
            self.propagate()
            row, col = self.get_lowest_entropy()
            iteration += 1
            if iteration % 100 == 0:
                print("iteration: {}".format(iteration))

        for row in range(self.wave_shape[0]):
            for col in range(self.wave_shape[1]):
                self.render_superpositions(row, col)

    # Determines the superposition of patterns at this position
    def render_superpositions(self, row, col):
        num_valid_patterns = sum(self.waves[row, col])
        self.out_img[row:row+self.dim, col:col+self.dim] = np.zeros((self.dim, self.dim, 3))
        for i in range(self.num_patterns):
            if self.waves[row, col, i]:
                self.out_img[row:row+self.dim, col:col+self.dim] += self.patterns[i] / num_valid_patterns

    # Finds the next tile of lowest entropy to collapse
    def get_lowest_entropy(self):
        lowest_val = -1
        r = -1
        c = -1
        # Checks all non-collapsed positions to find position of lowest entropy
        for col in range(self.wave_shape[1]):
            for row in range(self.wave_shape[0]):
                if not self.observed[row, col] and self.waves[row, col].any():
                    if lowest_val < 0 or (lowest_val > self.entropies[row, col] > 0):
                        lowest_val = self.entropies[row, col]
                        r = row
                        c = col
        return r, c

    # Performs a measurement on the tile of lowest entropy to collapse to
    # a single state
    def observe_wave(self, row, col, qrng=False):
        possible_indices = []
        sub_probs = []
        # Determines superposition of states and their total frequency counts.
        for i in range(self.num_patterns):
            if self.waves[row, col, i]:
                possible_indices.append(i)
                sub_probs.append(self.counts[i])

        collapsed_index = 0
        # Uses Python's numpy.random module depending on qrng flag
        # Randomly selects a state for collapse. Weighted by state frequency count.
        if not qrng:
            collapsed_index = np.random.choice(possible_indices, p=sub_probs/np.sum(sub_probs))
        else:
            # Use quantum random number generation to generate a random number
            # Selects an index according to the weighted probability distribution
            # based on this random number from qrng
            tot = int(np.sum(sub_probs)) - 1
            rand = randomInt.simulate(bound=tot)
            j = 0
            for i, w in enumerate(sub_probs):
                rand -= w
                if rand < 0:
                    j = i
                    break
            collapsed_index = possible_indices[j]

        # Collapse the state
        self.do_observe(row, col, collapsed_index)
        # Add this position to those we have to propagate changes from
        self.propagate_stack.append((row, col))

    # Performs the measurement
    def do_observe(self, row, col, pattern_index):
        self.observed[row, col] = True
        self.entropies[row, col] = 0
        self.waves[row, col] = np.full((self.num_patterns,), False)
        self.waves[row, col, pattern_index] = True
        # self.out_img[row:row+self.dim, col:col+self.dim] = self.patterns[pattern_index]

    # Propagates the changes from collapsing a tile to a single state throughout
    # the entire board.
    def propagate(self):
        iterations = 0
        while len(self.propagate_stack) > 0:
            # Get next position we have to propagate changes from
            row, col = self.propagate_stack.pop()
            self.registered_propogate[row, col] = False
            valid_indices = []
            # Finds valid indices where we have already observed the wave
            for i in range(self.num_patterns):
                if self.waves[row, col, i]:
                    valid_indices.append(i)

            if valid_indices is None or len(valid_indices) is 0:
                print("Error: contradiction with no valid indices")
                continue

            # Check all overlayed tiles to propagate changes
            for overlay_idx in range(len(self.overlays)):
                self.update_wave(row, col, overlay_idx, valid_indices)

            iterations += 1
            if iterations % 1000 == 0:
                print("propagation iteration: {}, propogation stack size: {}".format(iterations, len(self.propagate_stack)))

    # Actually makes the changes to the wave
    def update_wave(self, row, col, overlay_idx, valid_indices):
        col_shift, row_shift = self.overlays[overlay_idx]
        row_s = row+row_shift
        col_s = col+col_shift
        # If position is valid and non-collapsed, propagate changes through
        # this position
        if row_s >= 0 and row_s < self.wave_shape[0] and \
                col_s >= 0 and col_s < self.wave_shape[1] and \
                not self.observed[row_s, col_s]:
            changed = False
            valid_pattern_count = 0
            valid_pattern_idx = -1
            for i in range(self.num_patterns):
                if self.waves[row_s, col_s, i]:
                    can_fit = False
                    j = 0
                    while j < len(valid_indices) and not can_fit:
                        can_fit = self.fit_table[valid_indices[j], i, overlay_idx]
                        j += 1
                    if not can_fit:
                        self.waves[row_s, col_s, i] = False
                        # self.entropies[row_s, col_s] -= entropy_b2(self.probs[i])
                        self.entropies[row_s, col_s] -= 1
                        changed = True
                    else:
                        valid_pattern_count += 1
                        valid_pattern_idx = i
            if valid_pattern_count == 1:
                self.do_observe(row_s, col_s, valid_pattern_idx)
            if changed and not self.registered_propogate[row_s, col_s]:
                self.propagate_stack.append((row_s, col_s))
                self.registered_propogate[row_s, col_s] = True

    def create_waveforms(self, dim):
        height, width, depth = self.tiles[0].shape

        # Add all (D x D) subarrays and (if requested) all its rotations.
        for tile in self.tiles:
            for col in range(width + 1 - dim):
                for row in range(height + 1 - dim):
                    pattern = tile[row:row+dim, col:col+dim]
                    if self.rotate_patterns:
                        for rot in range(4):
                            self.add_waveform(np.rot90(pattern, rot))
                    else:
                        self.add_waveform(pattern)

        self.probs = np.array(self.counts) / sum(self.counts)

    def add_waveform(self, waveform):
        for i in range(len(self.patterns)):
            if np.array_equal(waveform, self.patterns[i]):
                self.counts[i] += 1
                return
        self.patterns.append(waveform)
        self.counts.append(1)

    def check_fits(self):
        self.fit_table = np.full((self.num_patterns, self.num_patterns, len(self.overlays)), False)

        for patt_idx1 in range(self.num_patterns):
            patt1 = self.patterns[patt_idx1]
            for patt_idx2 in range(self.num_patterns):
                patt2 = self.patterns[patt_idx2]

                for i in range(len(self.overlays)):
                    col_shift, row_shift = self.overlays[i]

                    row_start_1 = max(row_shift, 0)
                    row_end_1 = min(row_shift+self.dim-1, self.dim-1)
                    col_start_1 = max(col_shift, 0)
                    col_end_1 = min(col_shift+self.dim-1, self.dim-1)

                    row_start_2 = row_start_1 - row_shift
                    row_end_2 = row_end_1 - row_shift
                    col_start_2 = col_start_1 - col_shift
                    col_end_2 = col_end_1 - col_shift

                    self.fit_table[patt_idx1, patt_idx2, i] = np.array_equal(
                        patt1[row_start_1:row_end_1+1, col_start_1:col_end_1+1],
                        patt2[row_start_2:row_end_2+1, col_start_2:col_end_2+1])
