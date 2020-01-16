def negamax_agent(obs, config):
    from random import choice
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board) 
    
    max_depth = 7 #if made_moves < 20 else 8
    
    def board_eval(board, moves, column, mark):
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        score =0 
        if column > 0 and board[row * columns + column - 1] == mark:              #left same mark
            score += 1
        if (column < columns - 1 and board[row * columns + column + 1] == mark):  #right same mark
            score += 1        
        if row > 0 and column > 0 and board[(row - 1) * columns + column - 1] == mark:
            score += 1
        if row > 0 and column < columns - 1 and board[(row - 1) * columns + column + 1] == mark:
            score += 1           
        return score

    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):        
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:               
                return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.                           

        # Recursively check all columns.        
        best_score = -size               
        best_column = None
        for column in column_order: 
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                                        
                    score = board_eval(board, moves, column, mark)                   
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    score = score * -1            
                if score > best_score:
                    best_score = score
                    best_column = column            
                alpha = max(alpha, score) # reduce the [alpha;beta] window for next exploration, as we only                                                                   
                #print("mark: %s, d:%s, col:%s, score:%s (%s, %s)) alpha = %s beta = %s" % (mark, depth, column, score,best_score, best_column, alpha, beta))            
                if alpha >= beta:                        
                    return (alpha, best_column)  # prune the exploration if we find a possible move better than what we were looking for.                    
        return (alpha, best_column)
    
    if made_moves <= 1:
        best_column = columns//2
    else:
        best_score, best_column = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
        #print(obs.mark, made_moves, best_score, best_column)    
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column
