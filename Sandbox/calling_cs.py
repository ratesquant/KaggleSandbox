# -*- coding: utf-8 -*-
"""
Created on Mon Nov 29 21:29:11 2021

@author: chirokov
"""

#http://pythonnet.github.io/

import sklearn.metrics
import numpy as np


import clr
clr.AddReference(r'D:\Github\ACQ\ACQ.Excel\bin\Debug/ACQ.Excel.dll')

import ACQ.Excel

n = 100

for i in range(10000):
    actual = np.random.choice([1,0], n)
    predicted = np.random.rand(n)
    try:
        acq_auc = ACQ.Excel.StatUtils.acq_auc(actual, predicted)
        sk_auc = sklearn.metrics.roc_auc_score(actual, predicted)
        if abs(acq_auc - sk_auc) > 1e-16:
            print("%s %s %s %s" % (actual, predicted) )
    except:
        pass