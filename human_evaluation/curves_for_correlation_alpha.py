'''
Dependent system-level meta-evaluation
'''

import os
import re
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import make_interp_spline

# Directory containing the txt files
directory = 'correlation_score'


# Function to read the Pearson and Spearman values from a file
def read_values_from_file(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        # Extract Pearson and Spearman values
        pearson = float(re.search(r'Pearson:\s*(\d+\.\d+)', lines[0]).group(1))
        spearman = float(re.search(r'Spearman:\s*(\d+\.\d+)', lines[1]).group(1))
        return pearson, spearman


# Function to fit a smooth curve using spline and find the maximum point
def fit_spline(x, y):
    # Sort the x and corresponding y values
    sorted_x, sorted_y = zip(*sorted(zip(x, y)))
    sorted_x = np.array(sorted_x)
    sorted_y = np.array(sorted_y)

    spline = make_interp_spline(sorted_x, sorted_y, k=3)  # Cubic spline interpolation
    x_new = np.linspace(min(sorted_x), max(sorted_x), 500)
    y_new = spline(x_new)

    # Find the maximum point in the interpolated curve
    max_y = np.max(y_new)
    max_x = x_new[np.argmax(y_new)]

    return x_new, y_new, max_x, max_y


# Parse alpha from filename (e.g., "sorted_f_scores_alpha_0.0.txt" -> alpha = 0.0)
def parse_alpha_from_filename(filename):
    match = re.search(r'alpha_([0-9\.\-]+)\.txt$', filename)
    if match:
        return float(match.group(1))
    else:
        raise ValueError(f"Filename format is incorrect: {filename}")


# Data for TS (Alpha, Pearson, Spearman)
alpha_ts = []
pearson_ts = []
spearman_ts = []

# Data for EW (Alpha, Pearson, Spearman)
alpha_ew = []
pearson_ew = []
spearman_ew = []

# Read the files and parse the data
for filename in os.listdir(directory):
    if filename.endswith(".txt.txt"):  # Adjusted for extra '.txt' in filename
        file_path = os.path.join(directory, filename)
        try:
            pearson, spearman = read_values_from_file(file_path)
            alpha = parse_alpha_from_filename(filename)

            # Append the values to TS and EW lists based on the filename
            if 'ts' in filename.lower():
                alpha_ts.append(alpha)
                pearson_ts.append(pearson)
                spearman_ts.append(spearman)
            elif 'ew' in filename.lower():
                alpha_ew.append(alpha)
                pearson_ew.append(pearson)
                spearman_ew.append(spearman)
        except Exception as e:
            print(f"Error processing {filename}: {e}")

# Create figure and axes
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

# Plot for TS
ax1.set_title('TS - Pearson and Spearman vs Alpha', fontsize=14, fontweight='bold', family='Times New Roman')
ax1.set_xlabel('Alpha', fontsize=12, fontweight='bold', family='Times New Roman')
ax1.set_ylabel('Value', fontsize=12, fontweight='bold', family='Times New Roman')
ax1.scatter(alpha_ts, pearson_ts, label='Pearson', color='#1f77b4', zorder=5)  # Blue color
ax1.scatter(alpha_ts, spearman_ts, label='Spearman', color='#2ca02c', zorder=5)  # Dark Green color
x_smooth_ts, y_smooth_ts, max_x_pearson, max_y_pearson = fit_spline(alpha_ts, pearson_ts)
x_smooth_spearman, y_smooth_spearman, max_x_spearman, max_y_spearman = fit_spline(alpha_ts, spearman_ts)
ax1.plot(x_smooth_ts, y_smooth_ts, label='Fitted Pearson Curve', color='#1f77b4', linestyle='--', linewidth=2)
ax1.plot(x_smooth_spearman, y_smooth_spearman, label='Fitted Spearman Curve', color='#2ca02c', linestyle='--',
         linewidth=2)
ax1.legend()

# Plot for EW
ax2.set_title('EW - Pearson and Spearman vs Alpha', fontsize=14, fontweight='bold', family='Times New Roman')
ax2.set_xlabel('Alpha', fontsize=12, fontweight='bold', family='Times New Roman')
ax2.set_ylabel('Value', fontsize=12, fontweight='bold', family='Times New Roman')
ax2.scatter(alpha_ew, pearson_ew, label='Pearson', color='#1f77b4', zorder=5)  # Blue color
ax2.scatter(alpha_ew, spearman_ew, label='Spearman', color='#2ca02c', zorder=5)  # Dark Green color
x_smooth_ew, y_smooth_ew, max_x_pearson_ew, max_y_pearson_ew = fit_spline(alpha_ew, pearson_ew)
x_smooth_spearman_ew, y_smooth_spearman_ew, max_x_spearman_ew, max_y_spearman_ew = fit_spline(alpha_ew, spearman_ew)
ax2.plot(x_smooth_ew, y_smooth_ew, label='Fitted Pearson Curve', color='#1f77b4', linestyle='--', linewidth=2)
ax2.plot(x_smooth_spearman_ew, y_smooth_spearman_ew, label='Fitted Spearman Curve', color='#2ca02c', linestyle='--',
         linewidth=2)
ax2.legend()

# Show the plot with professional formatting
plt.tight_layout()
plt.show()

# Print maximum points
print(f"TS - Maximum Pearson at Alpha {max_x_pearson:.2f} with value {max_y_pearson:.3f}")
print(f"TS - Maximum Spearman at Alpha {max_x_spearman:.2f} with value {max_y_spearman:.3f}")
print(f"EW - Maximum Pearson at Alpha {max_x_pearson_ew:.2f} with value {max_y_pearson_ew:.3f}")
print(f"EW - Maximum Spearman at Alpha {max_x_spearman_ew:.2f} with value {max_y_spearman_ew:.3f}")
