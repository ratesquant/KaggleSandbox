#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 13 21:41:37 2020

@author: chirokov
"""

def CDT_f(x, i, g_i):
    return max(abs(x-i),g_i);

def CDT_sep(i, u, g_i, g_u):
    if g_i <= g_u:
        return max(i+g_u,(i+u)//2)
    else:
        return min(u-g_i,(i+u)//2)

def print_board(board, columns = 7):
    for i in range(len(board)//columns):
        print(board[(i*columns):((i+1)*columns)])

#https://github.com/adithyaselv/Distance-Transform/blob/master/dt.cpp

rows = 6
cols = 7
board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 1, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 2, 0, 0, 1, 1, 2, 1, 2, 0, 0]

board_dt = distance_transform(board, rows, cols)
%timeit distance_transform(board, rows, cols)

print_board(board)
print_board(board_dt)

def distance_transform(board, rows, cols, mark = 1):
    board2 = [0] * len(board)
    board_dt = [0] * len(board)
    #board[row * columns + column] 
    #First Phase - To find Function G 
    for i in range(rows):
        #if border is > 0 make it 0 else 255
        if board[i * cols] == mark: 
            board2[i * cols] = 0;
        else:
            board2[i * cols]=255;
    
        #check for obstacle in the entire row
        #Left to right pass
        for j in range(cols):    
            if board[i * cols + j]==mark:
                board2[i * cols + j]=0;
            else:
                board2[i * columns + j] = min(255,1+board2[i*cols + j-1])    
        #Right to left pass    
        for j in range(cols-2, -1, -1):        
            if board2[i * cols + j + 1] < board2[i * cols + j]:
                board2[i * cols + j]=min(255,1+board2[i * cols +j+1])
    
     #Second Phase - Compute Distance transform
            
    s = rows *[0]        
    t = rows *[0]       
    
    for j in range(cols):
        q=0;
        s[0]=0
        t[0]=0 
    
        for u in range(1, rows):         
            while(q>=0 and (CDT_f(t[q],s[q],board2[s[q]*cols + j]) > CDT_f(t[q],u,board2[u * cols + j]))):
                q = q - 1
            if q<0:
                q=0
                s[0]=u
            else:                
                w = 1+CDT_sep(s[q],u,board2[s[q]*cols+j],board2[u*cols+j]);
                if w<rows:
                    q= q + 1
                    s[q]=u
                    t[q]=w
          
        for u in range(rows - 1, -1,-1):
            board_dt[u*cols +j]= CDT_f(u,s[q],board2[s[q]*cols+j])
            if u == t[q]:
                q = q -1
    return board_dt


    