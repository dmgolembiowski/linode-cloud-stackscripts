#!/usr/bin/env python3
import time
import dill
import pandas as pd 
import sys
import pathlib
import os
from multiprocessing.pool import ThreadPool
from typing import Any, Callable, Optional
from functools import partial 

def parallelize(funcs: list[Callable[..., Any]], num_processes: int = 1) -> list[Any]:
    pool = ThreadPool(processes=num_processes)
    results = {}
    for idx, func in enumerate(funcs):
        results[idx] = pool.apply_async(func)

    return_results = []
    for _, res in results.items():
        return_results.append(res.get())

    pool.close()
    pool.terminate()
    return return_results

def process_linode(scope_no, idx_start, idx_end):
    cwd = str(os.getcwd())
    destdir = f'{cwd}/{scope_no}linode'
    os.system('mkdir -p {destdir}')
    sentinel_path = cwd + str(scope_no) + "sentinel.pkl"
    script_destination_dir =  destdir
    with open(sentinel_path, 'rb') as f:
        sentinel = dill.load(f)
    final = sentinel["final"]
    jobs = sentinel["jobs"]
    status = sentinel["status"]
    
    def update_sentinel_file(new_sentinel):
        nonlocal sentinel_path 
        with open(sentinel_path, 'wb') as f:
            dill.dump(new_sentinel, f)

    def write_script(filename, content, job_no):
        nonlocal scope_no 
        nonlocal sentinel_path 
        nonlocal script_destination_dir
        nonlocal sentinel 
        path = script_destination_dir + "/" + filename
        with open(path, 'w') as f:
            f.write(content)

        sentinel["status"][job_no] = True

    time.sleep(scope_no)

    for row_id in range(idx_start, idx_end):
        new_sentinel = None
        filename = jobs[row_id].get('filename')
        content = jobs[row_id].get('reference')
        write_script(filename=filename, content=content, job_no=row_id)
        status[row_id] = True 
        if row_id % 3 == 0:
            new_sentinel = dict(final=final, jobs=jobs, status=status)
        if row_id == idx_end - 1:
            new_sentinel = dict(final=final, jobs=jobs, status=status)
        if new_sentinel is not None: 
            update_sentinel_file(new_sentinel)


def process_linode_1(scope_no=1, idx_start=(1 - 1)*50, idx_end=1*50): 
    process_linode(scope_no, idx_start, idx_end)

def process_linode_2(scope_no=2, idx_start=(2 - 1)*50, idx_end=2*50): 
    process_linode(scope_no, idx_start, idx_end)

def process_linode_3(scope_no=3, idx_start=(3 - 1)*50, idx_end=3*50):
    process_linode(scope_no, idx_start, idx_end)

def process_linode_4(scope_no=4, idx_start=(4 - 1)*50, idx_end=4*50):
    process_linode(scope_no, idx_start, idx_end)

if __name__ == "__main__":
    tasks = [
        process_linode_1,
        process_linode_2,
        process_linode_3,
        process_linode_4,
    ]
    done = parallelize(tasks, num_processes=4)
