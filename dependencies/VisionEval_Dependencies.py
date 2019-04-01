import os
from pathlib import Path
import pandas as pd
import numpy as np # for repeat
import re
import collections # for counting number of times a packages is used in a script

# Pick repository version
home_dir = str(Path.home())

# Find location of VisionEval repository (or repositories).
# Assumes repo was cloned (i.e., includes .git). Will just pick the first one for now.
ve_dirs = []
for path, dir, subdirs in os.walk(home_dir):
    if re.search(r'VisionEval.+\.git$', str(path)):
            ve_dirs.append(path.rstrip('\.git'))

print("Found repositories:", *ve_dirs, sep ='\n')
ve_dir = ve_dirs[0]
print("Scanning first repository,", ve_dir)
# Export output to home directory for now, make this flexible later
export_dir = home_dir

repo_path = ve_dir.split("\\")
repo_name = repo_path[len(repo_path)-1]

R_packs = []

for dir, subdirs, files in os.walk(ve_dir):
    # Find .R files
    for file in files:
        if file.endswith(".R"):
            # Read the file and scan for @import statements.
            # Add encoding statement, otherwise fails for some files, likc CalculatePolicyVmt.R for some reason
            found = re.findall('@import .+', open(os.path.join(dir, file), encoding="utf-8").read())
            found_list = [packs for segments in found for packs in segments.split()]
            while '@import' in found_list: found_list.remove('@import')

            found_from = re.findall('@importFrom .+', open(os.path.join(dir, file), encoding="utf-8").read())
            found_from_list = [packs for segments in found_from for packs in segments.split()]
            found_from_list = found_from_list[:len(found_from_list)-1] # remove the function being imported
            while '@importFrom' in found_from_list: found_from_list.remove('@importFrom')
            
            found_list.extend(found_from_list)
            counter = collections.Counter(found_list)
            if(len(counter)==0):
                df = pd.DataFrame(data = {'dir': str(dir), 'file': str(file), 'package': [np.nan], 'count': [np.nan]})
            else:
                df = pd.DataFrame.from_dict(counter, orient='index').reset_index()
                df.columns = ['package', 'count']
                df["dir"] = pd.Series(list(np.repeat([dir], len(df))))
                df["file"] = pd.Series(list(np.repeat([file], len(df))))
            R_packs.append(df)

R_packs = pd.concat(
  R_packs, ignore_index=True, verify_integrity=True, sort = False)

outfile = repo_name + '_Dependency_Scan.csv'
print('Exporting ' + outfile + ' to ' + export_dir)

R_packs.to_csv(os.path.join(export_dir, outfile))

results = R_packs.groupby('package').agg({'count': 'sum'})

results.sort_values('count', inplace=True)

outfile = repo_name + '_Dependency_Summary.csv'
print('Exporting ' + outfile + ' to ' + export_dir)

results.to_csv(os.path.join(export_dir, outfile))